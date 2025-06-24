require 'aethyr/core/gary'
require 'gdbm'
require 'digest/md5'
require 'thread'
require 'aethyr/core/util/guid'
require 'aethyr/core/util/log'
require 'aethyr/core/errors'
require 'aethyr/core/objects/player'
require 'aethyr/core/objects/room'
require 'aethyr/core/objects/area'
require 'aethyr/core/objects/mobile'
require 'aethyr/extensions/objects/clothing_items'
require 'aethyr/extensions/flags/elements'
load 'aethyr/core/util/all-behaviors.rb'
load 'aethyr/core/util/all-objects.rb'

# Storage class for object persistance. Uses GDBM.
#
# GDBM is a file-system hash table which is fast and available on many
# platforms. However, it only stores strings. So objects are stored as Strings
# representing the marshaled object.
#
# The default storage system works this way: each GameObject is stored in a
# file which is named after the GameObject's class. For example, a Door would
# be in storage/Door. In each file, objects are indexed by their GOID. There
# is a special file in storage/goids which lists GOIDs and the class of the
# GameObject. This is used to find Objects according to their GOID.
#
# Here is an example: you want to load an object with a GOID of
# 476dfe3e-96bc-1952-fadd-26c22043a5a3. The StorageMachine will first open up
# storage/goids and retrieve the class pointed to by
# 476dfe3e-96bc-1952-fadd-26c22043a5a3, which happens to be Dog. The
# StorageMachine then opens up storage/Dog and again retrieves the Object
# pointed to by 476dfe3e-96bc-1952-fadd-26c22043a5a3, but this time it will be
# the (marshaled string of the) Dog object.
#
# Of course, there are exceptions. Players are handled differently, because
# they are typically looked up by name and not by their GOID. Instead of being
# listed in storage/goids, they are listed in storage/players. This file maps
# player names to GOIDs. Then they can be looked up by GOID in the
# storage/Player file. Additionally, passwords are stored as MD5 hashes in
# storage/passwords, indexed by GOID (a tiny bit of security there).
class StorageMachine
  def initialize(path = 'storage/')
    @path = path
    @mutex = Mutex.new
    @saved = 0
  end

  #This is the save function for a Player, since they need special handling.
  #
  #If password is something other than nil, then it saves the password. You
  #MUST DO THIS IF THIS IS A NEW PLAYER YOU ARE SAVING. OTHERWISE, the player
  #will be lost to you. Sorry!
  def save_player(player, password = nil)
    player_name = player.name.downcase
    open_store("players", false) do |gd|
      gd[player_name] = player.goid
    end
    unless password.nil?
      open_store("passwords", false) do |gd|
        gd[player.goid] = Digest::MD5.new.update(password).to_s
      end
    end

    log "Saving player: #{player.name}"
    store_object(player)

    player.inventory.each do |o|
      store_object(o)
    end

    # If event sourcing is enabled, ensure player exists in event store
    if defined?(ServerConfig) && ServerConfig[:event_sourcing_enabled] && password
      # Check if player exists in event store
      begin
        Sequent.aggregate_repository.load_aggregate(player.goid)
      rescue Sequent::Core::AggregateRepository::AggregateNotFound
        # Create player in event store
        password_hash = Digest::MD5.new.update(password).to_s
        command = Aethyr::Core::EventSourcing::CreatePlayer.new(
          id: player.goid,
          name: player.name,
          password_hash: password_hash
        )
        Sequent.command_service.execute_commands(command)
      end
    end

    log "Player saved: #{player.name}"
  end

  #Sets password for a given player. Accepts player name or player object.
  def set_password(player, password)
    goid = nil
    name = nil
    if player.is_a? String
      name = player
    else
      name = player.name
    end

    open_store "players" do |gd|
      goid = gd[name.downcase]
    end

    password_hash = Digest::MD5.new.update(password).to_s
    open_store("passwords", false) do |gd|
      gd[goid] = password_hash
    end
    
    # If event sourcing is enabled, update password in event store
    if defined?(ServerConfig) && ServerConfig[:event_sourcing_enabled] && goid
      command = Aethyr::Core::EventSourcing::UpdatePlayerPassword.new(
        id: goid,
        password_hash: password_hash
      )
      Sequent.command_service.execute_commands(command)
    end
  end

  #Check if a player with the same name already exists in storage.
  def player_exist?(name)
    open_store "players" do |gd|
      gd.has_key? name.downcase
    end
  end

  #Returns the type of the object with the supplied goid
  def type_of goid
    open_store "goids" do |gd|
      type = gd[goid]
      if type
        Object.const_get type.to_sym
      else
        nil
      end
    end
  end

  #Looks up name, compares MD5 sum of password to the stored password,
  #and loads the player.
  def load_player(name, password, game_objects)
    goid = nil

    open_store "players" do |gd|
      goid = gd[name.downcase]
    end

    if goid.nil?
      log "Could not fetch player info #{name}", Logger::Ultimate
      raise MUDError::UnknownCharacter
    end

    unless check_password name, password
      raise MUDError::BadPassword
    end

    log "Loading player...#{goid}"
    return load_object(goid, game_objects)
  end

  def check_password(name, password)
    stored_password = nil
    goid = nil
    open_store "players" do |gd|
      goid = gd[name.downcase]
    end
    open_store "passwords" do |gd|
      stored_password = gd[goid]
    end

    if stored_password.nil?
      log "Could not fetch password for #{name}", Logger::Ultimate
      raise MUDError::UnknownCharacter
    end

    if Digest::MD5.new.update(password).to_s != stored_password
      log "Passwords did not match: #{stored_password} and #{Digest::MD5.new.update(password).to_s}", Logger::Ultimate
      false
    else
      true
    end
  end

  #Deletes a character.
  def delete_player(name)
    name = name.downcase
    log "Deleting player #{name}", Logger::Ultimate

    goid = nil

    open_store("players", false) do |gd|
      goid = gd[name]
      gd.delete(name)
    end

    if goid.nil?
      log "Could not fetch player info #{name}", Logger::Ultimate
      return nil
    end

    open_store("passwords", false) do |gd|
      gd.delete goid
    end

    return delete_object(goid)
  end

  #Recursively stores object and its inventory.
  #
  #Warning: this temporarily removes the object's subscribers.
  def store_object(object)

    volatile_data = object.dehydrate()

    open_store("goids", false) do |gd|
      gd[object.goid] = object.class.to_s
    end

    open_store(object.class, false) do |gd|
      gd[object.goid] = Marshal.dump(object)
    end

    if object.respond_to? :equipment
      object.equipment.each do |o|
        store_object(o) unless o.is_a? Aethyr::Core::Objects::Player #this shouldn't happen, but who knows
      end
    end

    @saved += 1

    object.rehydrate(volatile_data)
    
    # If event sourcing is enabled, ensure object exists in event store
    if defined?(ServerConfig) && ServerConfig[:event_sourcing_enabled]
      # Check if object exists in event store
      begin
        Sequent.aggregate_repository.load_aggregate(object.goid)
      rescue Sequent::Core::AggregateRepository::AggregateNotFound
        # Create object in event store
        command = Aethyr::Core::EventSourcing::CreateGameObject.new(
          id: object.goid,
          name: object.name,
          generic: object.generic,
          container_id: object.container
        )
        Sequent.command_service.execute_commands(command)
      end
    end

    log "Stored #{object} # #{object.game_object_id}", Logger::Ultimate
  end

  #Removes object from store. Object can be an actual GameObject or a GOID
  def delete_object(object)
    store = nil
    file = nil
    game_object_id = nil
    game_object = nil

    if not object.is_a? GameObject
      game_object_id = object

      open_store "goids" do |gd|
        file = gd[game_object_id]
      end

      if file.nil?
        log "No file found for that goid (#{game_object_id})", Logger::Ultimate
        return nil
      end
    else
      game_object_id = object.game_object_id
      file = object.class.to_s
    end

    open_store(file, false) do |gd|
      gd.delete(game_object_id)
    end

    open_store("goids", false) do |gd|
      gd.delete(game_object_id)
    end
    
    # If event sourcing is enabled, mark object as deleted in event store
    if defined?(ServerConfig) && ServerConfig[:event_sourcing_enabled] && game_object_id
      command = Aethyr::Core::EventSourcing::DeleteGameObject.new(
        id: game_object_id
      )
      Sequent.command_service.execute_commands(command)
    end
  end

  #Recursively loads an object and its inventory.
  def load_object(game_object_id, game_objects)
    object = nil
    file = nil

    open_store "goids" do |gd|
      file = gd[game_object_id]
    end

    if file.nil?
      log "No file found for that goid (#{game_object_id})", Logger::Ultimate
      raise MUDError::NoSuchGOID
    end

    open_store file do |gd|
      object = Marshal.load(gd[game_object_id])
    end

    if object.nil?
      log "Tried to load object (#{game_object_id}), but got nil", Logger::Ultimate
      raise MUDError::ObjectLoadError
    end

    if object.respond_to? :inventory
      log "Loading inventory for #{object}", Logger::Ultimate
      load_too = object.inventory.map{ |e| e[0]}
      object.inventory = Inventory.new(object.inventory.capacity)
      load_too.each do |goid|
        if game_objects.find_by_id(goid)
          obj = game_objects.find_by_id(goid)
        else
          obj = load_object(goid, game_objects)
        end

        #Don't want to load players until they are playing.
        #We can add the player to a room once they login, not before.
        object.inventory << obj unless obj.is_a? Aethyr::Core::Objects::Player
        obj.container = object.goid
      end
    end

    if object.respond_to? :equipment
      log "Loading equipment for #{object}", Logger::Ultimate
      load_too = object.equipment.inventory.map{ |e| e[0]}
      object.equipment.inventory = Inventory.new
      load_too.each do |goid|
        if game_objects.find_by_id(goid)
          obj = game_objects.find_by_id(goid)
        else
          obj = load_object(goid, game_objects)
        end

        #Don't want to load players until they are playing.
        #We can add the player to a room once they login, not before.
        unless obj.is_a? Aethyr::Core::Objects::Player or obj.nil?
          object.equipment.inventory << obj
          obj.info.equipment_of = object.goid
        end

        #Remove object if it does not seem to exist any longer
        if obj.nil?
          object.equipment.delete(goid)
        end
      end

      object.load_defaults
    end


    object.rehydrate(nil)
    game_objects << object

    unless object.container.nil? or game_objects.loaded? object.container
      begin
        load_object(object.container, game_objects)
      rescue MUDError::NoSuchGOID, MUDError::ObjectLoadError
        object.container = ServerConfig.start_room
      end
    end

    return object
  end

  #Loads all GameObjects back into a Gary.
  #Except for players. Unless you want them.
  #
  #This method isn't very efficient. Sorry.
  def load_all(include_players = false, game_objects = nil)
    log "Loading all game objects...may take a while.", Logger::Ultimate
    files = {}
    objects = []
    game_objects ||= Gary.new

    log "Grabbing all the goids...", Logger::Ultimate

    #Get which goids are in which files, so we can pull them out.

    open_store "goids" do |gd|
      gd.each_pair do |k,v|
        if files[v].nil?
          files[v] = [k]
        else
          files[v] << k
        end
      end
    end

    #Don't want to load players, unless specified that we do
    files.delete(Aethyr::Core::Objects::Player) unless include_players

    #Load each object.
    files.each do |type, ids|
      open_store type do |gd|
        ids.each do |id|
          object = Marshal.load(gd[id])
          log "Loaded #{object}", Logger::Ultimate
          unless object.nil? or (not include_players and object.is_a? Aethyr::Core::Objects::Player)

            object.rehydrate(nil)

            game_objects << object
            objects << object
          end
        end
      end
    end

    log "Loading inventories and equipment...", Logger::Ultimate
    #Setup inventory and equipment for each one.
    objects.each do |obj|
      load_inv(obj, game_objects)
      load_equipment(obj, game_objects)
    end
    log "...done loading inventories and equipment.", Logger::Ultimate

    return game_objects
  end

  #Saves all objects in the game_objects Gary.
  #
  #This should mainly be used when the game exits,
  #as it briefly mutilates the objects.
  def save_all(game_objects)
    log "Saving given objects (#{game_objects.length})...please wait...", Logger::Ultimate
    @saved = 0
    game_objects.each do |o|
      if o.is_a? Aethyr::Core::Objects::Player
        save_player(o)
      else
        store_object(o)
      end
    end
    log "...done saving objects (#{@saved}).", Logger::Ultimate
  end

  #Open the store for the given type.
  def open_store(file, read_only = true)
    file = file.to_s
    if read_only
      flags = GDBM::READER + GDBM::NOLOCK
    else
      flags = GDBM::SYNC + GDBM::NOLOCK
    end
    @mutex.synchronize do
      GDBM.open(@path + file, 0666, flags) do |gd|
        yield gd
      end
    end
  end

  #Sets the inventory for the given object, out of the given
  #game objects.
  def load_inv(object, game_objects)

    if not object.respond_to? :inventory
      #log "#{object} has no inventory"
      return
    elsif object.inventory.nil?  #I can't think of when this might happen
      object.inventory = Inventory.new
      #log "#{object} had a nil inventory"
      return
    elsif object.inventory.empty?
      object.inventory = Inventory.new(object.inventory.capacity)
      #log "#{object} has nothing in its inventory"
      return
    end

    inv = Inventory.new(object.inventory.capacity)

    object.inventory.each do |inv_obj|
      if game_objects.include? inv_obj[0]
        obj = game_objects[inv_obj[0]]
        pos = inv_obj[1]
        unless obj.is_a? Aethyr::Core::Objects::Player
          inv.add(obj, pos)
          obj.container = object.goid
        end
        #log "Added #{obj} to #{object}"
      else
        log "Don't have #{inv_obj} loaded...what does that mean? (Probably a Player)", Logger::Medium
      end
    end

    object.inventory = inv
  end

  #Sets the equipment for the given object, out of the given
  #game objects.
  def load_equipment(object, game_objects)

    if not object.respond_to? :equipment
      #log "#{object} has no equipment"
      return
    end

    load_inv(object.equipment, game_objects)
    object.equipment.each do |o|
      o.info.equipment_of = object.goid
    end
  end

  #THIS IS DANGEROUS
  #
  #THIS IS DANGEROUS - WHATEVER YOU DO, DO NOT RUN ON LIVE SERVER
  #
  #THIS IS DANGEROUS
  #
  #Each object will be loaded and passed into the block supplied.
  #You can do whatever you want to the object in that block.
  #Then whatever is returned will be saved and you can move on to the next object.
  #
  #THIS IS REALLY DANGEROUS
  def update_all_objects!
    load_all(true).each do |game_object|
      game_object = yield game_object
      store_object(game_object)
    end
  end

  # Migrates existing game objects to the event store.
  #
  # This method loads all game objects from the traditional storage system
  # and creates corresponding events in the event store to establish a complete
  # history. It handles different types of game objects (players, rooms, and
  # regular game objects) and creates appropriate commands for each.
  #
  # The migration process is atomic - either all objects are successfully
  # migrated or none are. This ensures data consistency between the traditional
  # storage system and the event store.
  #
  # @return [Boolean] true if migration was successful, false otherwise
  # @raise [LoadError] If the Sequent gem is not available
  # @raise [RuntimeError] If there is an error during migration
  def migrate_to_event_store
    return false unless defined?(ServerConfig) && ServerConfig[:event_sourcing_enabled]
    
    # Check if Sequent is available
    begin
      require 'sequent'
    rescue LoadError => e
      log "Cannot migrate to event store: #{e.message}", Logger::Ultimate
      log "Make sure the sequent gem is installed", Logger::Ultimate
      return false
    end
    
    # Initialize Sequent if not already done
    unless defined?(Sequent.configuration) && Sequent.configuration.event_store
      return false unless Aethyr::Core::EventSourcing::SequentSetup.configure
    end
    
    log "Starting migration of all objects to event store...", Logger::Medium
    
    # Load all objects
    game_objects = load_all(true)
    
    # Create commands for each object
    commands = []
    
    # Process players first
    players = game_objects.find_all("class", Aethyr::Core::Objects::Player)
    players.each do |player|
      # Get password hash
      password_hash = nil
      open_store "passwords" do |gd|
        password_hash = gd[player.goid]
      end
      
      # Create player command
      commands << Aethyr::Core::EventSourcing::CreatePlayer.new(
        id: player.goid,
        name: player.name,
        password_hash: password_hash || "migrated",
        admin: player.admin
      )
      
      # Add container command
      commands << Aethyr::Core::EventSourcing::UpdateGameObjectContainer.new(
        id: player.goid,
        container_id: player.container
      )
    end
    
    # Process rooms
    rooms = game_objects.find_all("class", Aethyr::Core::Objects::Room)
    rooms.each do |room|
      # Create room command
      commands << Aethyr::Core::EventSourcing::CreateRoom.new(
        id: room.goid,
        name: room.name,
        description: room.long_desc
      )
      
      # Add exits if available
      if room.respond_to?(:exits) && room.exits
        room.exits.each do |direction, exit_obj|
          if exit_obj.respond_to?(:exit_room)
            commands << Aethyr::Core::EventSourcing::AddRoomExit.new(
              id: room.goid,
              direction: direction,
              target_room_id: exit_obj.exit_room
            )
          end
        end
      end
    end
    
    # Process other game objects
    game_objects.each do |obj|
      next if obj.is_a?(Aethyr::Core::Objects::Player) || obj.is_a?(Aethyr::Core::Objects::Room)
      
      # Create game object command
      commands << Aethyr::Core::EventSourcing::CreateGameObject.new(
        id: obj.goid,
        name: obj.name,
        generic: obj.generic,
        container_id: obj.container
      )
    end
    
    # Execute all commands
    log "Executing #{commands.size} commands to migrate objects to event store", Logger::Medium
    Sequent.command_service.execute_commands(*commands)
    
    log "Migration to event store completed", Logger::Medium
    return true
  end

  public :update_all_objects!, :migrate_to_event_store
end
