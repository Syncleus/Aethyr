require 'aethyr/core/cache_gary'
require 'aethyr/core/components/event_handler'
require 'aethyr/core/components/storage'
require 'aethyr/core/errors'
require 'aethyr/core/objects/info/calendar'
require 'aethyr/core/registry'
require 'aethyr/core/util/publisher'
require 'aethyr/core/util/priority_queue'
require 'set'
require 'aethyr/core/objects/integration_mock_room'
require 'aethyr/core/objects/integration_mock_player'

#The Manager class uses the wisper to recieve commands from objects, which
#it then passes along to the EventHandler.
#The Manager also keeps track of all game objects and takes care of adding, removing, and
#finding them.
#
#The server's Manager is a global named $manager.
class Manager < Publisher
  attr_reader :soft_restart, :uptime, :calendar

  #Creates a new Manager (only need one, though!)
  #
  #The objects parameter is not for general use, but when you want to use
  #a Manager object in an external script.
  def initialize(objects = nil)
    Aethyr::Extend::HandlerRegistry.handle(self)

    @soft_restart = false
    @storage = StorageMachine.new
    @uptime = Time.new.to_i
    @future_actions = PriorityQueue.new
    @pending_actions = PriorityQueue.new

    unless objects
      @cancelled_events = Set.new

      log "Loading objects from storage..."
      @game_objects = @storage.load_all(false, CacheGary.new(@storage, self))
      log "#{@game_objects.length} objects have been loaded."

      @calendar = Calendar.new

      @event_handler = EventHandler.new(@game_objects)

      @running = true
    else
      @game_objects = objects
    end
  end

  def submit_action( action, priority: 0, wait: nil )
    if wait.nil? || wait <= 0
      @pending_actions.push(action, priority)
    else
      activate_when = Manager::epoch_now + wait
      @future_actions.push({:action => action, :priority => priority}, activate_when)
    end
  end

  def pop_action
    # first check for any future actions ready to become active
    when_next = @future_actions.min_priority
    while when_next && when_next < Manager::epoch_now do
      future_next = @future_actions.pop_min
      @pending_actions.push(future_next[:action], future_next[:priority])
      when_next = @future_actions.min_priority
    end

    #return and pop whatever the next thing in the queue is.
    return @pending_actions.pop_min
  end

  #Checks if a game object ID exists already, to avoid conflicts.
  def existing_goid? goid
    @game_objects[goid] || @storage.type_of(goid)
  end

  #Returns Gary#type_count for the game objects.
  def type_count
    @game_objects.type_count
  end

  #Returns Number of game objects.
  def game_objects_count
    @game_objects.count
  end

  #Stop processing commands.
  def stop
    @event_handler.stop
    @running = false
  end

  #Resume processing commands.
  def start
    @event_handler.start
    @running = true
  end

  #Save all objects.
  def save_all
    stop
    @storage.save_all(@game_objects)
    start
  end

  #Adds a newly created Player.
  def add_player(player, password)
    @storage.save_player(player, password)
    self.add_object(player)
  end

  def set_password(player, password)
    @storage.set_password(player, password)
  end

  #Calls find_all on @game_objects
  def find_all(attrib, query)
    @game_objects.find_all(attrib, query)
  end

  #Loads player from storage, if passwords match and the Player exists.
  #
  #If player is already loaded, this function raises MUDError::CharacterAlreadyLoaded.
  def load_player(name, password)
    player = @game_objects.find(name, Aethyr::Core::Objects::Player) #should return nil unless player is logged in
    if player
      player.output "<important>Someone is trying to login as you.</>"
      if @storage.check_password(name, password)
        player.output "<important>Someone successfully logged in as you.</a>"
        drop_player(player)
      end
    end

    player = @storage.load_player(name, password, @game_objects)
    player.balance = true
    player.info.in_combat = false
    player.alive = true
    if player.info.stats.health and player.info.stats.health < 0
      player.info.stats.health = player.info.stats.max_health
    end
    player
  end

  #Calls Storage#check_password
  def check_password(name, password)
    @storage.check_password(name, password)
  end

  #Checks Storage to see if the player exists
  def player_exist?(name)
    log "Checking existence of #{name}", Logger::Medium
    @storage.player_exist?(name)
  end

  #Checks if the object is currently loaded in memory
  def object_loaded?(goid)
    @game_objects.loaded?(goid)
  end

  #Gets an object by goid
  def get_object(goid)
    @game_objects[goid]
  end

  #Creates a new object, adds to manager, puts it in the specified room, and sets its instance variables.
  #
  #init_args can be a single value or an Array and will be passed to the new() call.
  #
  #Vars should be a hash of variable symbols and values.
  #
  #Example:
  #
  #create_object(Box, room, nil, nil, :@open => false)
  def create_object(klass, room = nil, position = nil, args = nil, vars = nil)
    object = nil
    if room.is_a? Aethyr::Core::Objects::Container
      room_goid = room.goid
    else
      room_goid = room
      room = $manager.get_object room
    end
    if args
      if args.is_a? Enumerable
        object = klass.new(*args)
      else
        object = klass.new(args)
      end
    else
      object = klass.new(nil, room_goid)
    end

    if vars
      vars.each do |k,v|
        object.instance_variable_set(k, v)
      end
    end

    add_object(object, position)
    unless room.nil?
      if position == nil
        room.add(object)
      else
        room.add(object, position)
      end
    end
    object
  end

  #Add GameObject to the game.
  def add_object(game_object, position = nil)

    @game_objects << game_object unless @game_objects.loaded? game_object.goid

    broadcast(:object_added, { :publisher => self, :game_object => game_object, :position => position})

    unless game_object.room.nil?
      room = @game_objects[game_object.room]
      unless room.nil?
        if room.is_a? Aethyr::Core::Objects::Area
          room.add(game_object, position)
        else
          room.add(game_object)
        end
      end
    end

    @storage.store_object(game_object) unless game_object.is_a? Aethyr::Core::Objects::Player

    log "Added an object! (#{game_object.name})", Logger::Medium

    if game_object.is_a? Aethyr::Core::Objects::Player
      @game_objects.find_all("@admin", true).each do |admin|
        admin.output "#{game_object.name} has entered the game."
      end

      if game_object.room.nil?
        if game_object.info.former_room
          game_object.container = game_object.info.former_room
        else
          game_object.container = ServerConfig.start_room
        end
      end

      room = @game_objects[game_object.room]
      if room
        room.output("A plume of smoke suddenly descends nearby. As it clears, #{game_object.name} fades into view.", game_object)
      end
    end
  end

  #Delete a character.
  def delete_player(name)
    if not player_exist? name
      log "Tried to delete #{name} but no player found with that name."
      return
    end

    player = @game_objects.find(name, Aethyr::Core::Objects::Player)

    if player.nil?
      set_password name, "deleting"
      player = load_player name, "deleting"
    end

    player.inventory.each do |o|
      delete_object(o)
    end

    player.equipment.each do |o|
      delete_object(o)
    end

    if player.room
      room = @game_objects.find_by_id(player.room)
      if room
        room.remove(player)
      end
    end

    @game_objects.remove(player)

    player.inventory = nil

    player = nil

    @storage.delete_player(name)
  end

  #Remove GameObject from the game completely.
  def delete_object(game_object)
    leave_in_room = nil

    #See if we need to drop anything the object is holding
    unless game_object.container.nil?
      container = @game_objects.find_by_id(game_object.container)
      unless container.nil?
        if container.is_a? Container
          container.remove game_object
        else
          container.inventory.remove(game_object)
        end
        if container.can? :equipment
          container.equipment.delete game_object
        end
        if container.is_a? Room
          container.remove(game_object)
          leave_in_room = container
        end
      end
    end

    if game_object.info.equipment_of
      container = @game_objects.find_by_id(game_object.info.equipment_of)
      container.equipment.delete game_object.goid unless container.nil?
    end

    if leave_in_room.nil?
      leave_in_room = @game_objects.find('Garbage Dump', Room)
    end

    if game_object.can? :inventory
      game_object.inventory.each do |o|
        if leave_in_room
          leave_in_room.add(o)
          o.container = leave_in_room.goid
        end
      end
    end

    if game_object.can? :equipment
      game_object.equipment.each do |o|
        game_object.equipment.remove o
        if leave_in_room
          leave_in_room.add o
          o.container = leave_in_room.goid
        end
      end
    end

    @game_objects.remove(game_object)

    @storage.delete_object(game_object)
    game_object = nil
  end

  #Drop Player from the game (disconnect them).
  #Called when a player quits.
  def drop_player(game_object)
    return if game_object.nil?
    log "Dropping player #{game_object.name}"

    @storage.save_player(game_object)

    room = @game_objects[game_object.room]

    unless room.nil?
      room.output("#{game_object.name} vanishes in a poof of smoke.", game_object)
      room.remove(game_object)
    end

    if game_object
      @game_objects.delete(game_object)
      game_object.output("Farewell, for now.")

      game_object.quit
    end

    log "Dropped player #{game_object.name}"
    game_object = nil

  rescue Exception => e
    log e.inspect
    log(e.backtrace.join("\n"))
    log "Error when dropping player, but recovering and continuing."
  end

  #Calls update on all objects.
  def update_all
    #require 'benchmark'
    #updated = 0
    #Benchmark.bm {|t|
    #t.report("Tick update") do
    @game_objects.each do |go|
      go.update
      # updated += 1
    end
    #end
    #}
    #log "Updated #{updated} objects", Logger::Medium

    @calendar.tick
  end

  #Sends alert to all players.
  def alert_all(message = "<important>Server is shutting down, sorry!</important>", ignore_lost = true)
    @game_objects.find_all('class', Aethyr::Core::Objects::Player).each do |object|
      begin
        unless ignore_lost and object.container.nil?
          object.output message
        end
      rescue
      end
    end
  end

  #Finds the object in the container. If container is nil, then searches whole world.
  def find(name, container = nil, findall = false)
    if container.nil?
      if findall
        @game_objects.find_all('@generic', name)
      else
        @game_objects.find(name)
      end
    elsif container.is_a? HasInventory
      container.search_inv(name)
    elsif not container.is_a? GameObject
      container = @game_objects.find(container)
      if container.nil?
        return nil
      else
        return find(name, container)
      end
    end
  end

  #Restarts server.
  def restart
    alert_all("<important>Server is restarting. Please come back in a moment.</important>")
    @soft_restart = true
    $manager.stop
    EventMachine.add_timer(3) { EventMachine.stop_event_loop }
  end

  #Calendar#time
  def time
    @calendar.time
  end

  #Calendar#date
  def date
    @calendar.date
  end

  #Calendar#date_at
  def date_at timestamp
    @calendar.date_at timestamp
  end

  def to_s
    "The Manager"
  end

  private
  def self.epoch_now
    return DateTime.now.strftime('%s').to_i
  end
end
