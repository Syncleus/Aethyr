require 'aethyr/core/util/publisher'
require 'aethyr/core/util/log'
require 'aethyr/core/objects/inventory'
require 'aethyr/core/objects/traits/lexicon'
require 'aethyr/core/util/guid'
require 'aethyr/core/objects/info/info'
require 'aethyr/core/event'
require 'aethyr/core/util/defaults'

module Aethyr
  module Core
    module Objects
      #Base class for all game objects, including players. Should be subclassed to do anything useful.
      class GameObject < Publisher
        include Lexicon
        include Defaults

        attr_reader :short_desc, :game_object_id, :alt_names, :generic, :article, :sex, :gender, :show_in_look, :actions, :balance, :admin, :manager
        attr_accessor :container, :show_in_look, :actions, :pose, :visible, :comment, :movable, :quantity, :info
        attr_writer :plural
        alias :room :container
        alias :can? :respond_to?
        alias :goid :game_object_id

        default(:gender) do |this|
          if this.sex == 'm'
            Lexicon::Gender::MASCULINE
          elsif this.sex == 'f'
            Lexicon::Gender::FEMININE
          else
            Lexicon::Gender::NEUTER
          end
        end
        default(:visible) { true }

        #Creates a new GameObject. Most of this long list of parameters is simply ignored at creation time,
        #because they can all be set later.
        def initialize(game_object_id = nil, container = nil, name = "", alt_names = Array.new, short_desc = "Nothing interesting here.", long_desc = "", generic = "", sex = "n", article = "a")
          @info = Info.new
          @info.flags = Hash.new
          #Where the object is
          @container = container
          #The name of the object
          @name = name
          #Alternate names for the object
          @alt_names = alt_names
          @attributes = Hash.new
          #The short description of the object
          @short_desc = short_desc
          #The long, detailed description of the object
          @long_desc = long_desc
          #The generic description of the object (e.g., 'spoon')
          @generic = generic
          #The sex of the object
          @sex = sex
          #The article of the object ('a','an',etc)
          @article = article
          #This is tricky. If @show_in_look is something
          #other than false (or nil), then the object will
          #not show up in the list of objects, but rather this
          #description (in @show_in_look) will be shown as
          #part of the room's description.
          @show_in_look = false
          #How many? I dunno if this is useful yet.
          @quantity = 1
          #If this object can be picked up/moved
          @movable = false
          #Pose
          @pose = nil
          #Busy (running update)
          @busy = false
          #Plural
          @plural = nil
          #Comments for builders/coders/etc
          @comment = nil
          #Grab a new goid if one was not provided
          if game_object_id.nil?
            begin
              @game_object_id = Guid.new.to_s
            end while $manager.existing_goid? @game_object_id
          else
            @game_object_id = game_object_id
          end
          @plural = nil
          @actions = Set.new
          @admin = false

          load_defaults
    
          # If event sourcing is enabled and this is a new object, emit creation event
          if defined?(ServerConfig) && ServerConfig[:event_sourcing_enabled] && $manager && !$manager.existing_goid?(@game_object_id)
            # This will be handled by Manager#create_object or Manager#add_player
          end
        end

        def attributes
          @attributes.clone
        end

        def attach_attribute(attribute)
          @attributes[attribute.class] = attribute
        end

        def detach_attribute(attribute)
          if attribute.is_a? Class
            @attributes.delete(attribute)
          else
            attribute_to_detach = @attributes[attribute.class]
            if attribute == attribute_to_detach
              @attributes.delete(attribute.class)
            end
          end
        end

        def broadcast_from(event, *args)
          broadcast(event, *args)
        end

        def flags
          Hash.new @info.flags
        end

        def add_flag(new_flag)
          new_flag.negate_flags(@info.flags)
          @info.flags[new_flag.id] = new_flag
        end

        #Outputs a string to the object.
        def output(string, suppress_prompt = false)
          #fill in subclasses
        end

        #Just calls #alert.
        def out_event(event)
          alert(event)
        end

        #Generic 'tick' function called to update the object's state.
        #
        #Calls GameObject#run , which is where any "thinking" or decision
        #logic should go.
        def update
          return if @busy
          @busy = true
          begin
            if self.is_a? Reacts
              self.alert(Event.new(:Generic, :action => :tick))
            end
            run
          ensure
            @busy = false
          end
        end

        #Checks if the GameObject is busy in the GameObject#update method.
        #This prevents the update method from being called more than once
        #at a time.
        def busy?
          @busy
        end

        #Returns plural form of object's name.
        def plural
          return @plural if @plural
          if @generic
            "#{@generic}s"
          elsif @name
            "#{@names}s"
          else
            "unkowns"
          end
        end

        #Run any logic you need (thinking).
        #
        #To be implemented in the subclasses
        def run
        end

        #Basically, this is where hooks for commands would go.
        def alert(event)
        end

        #This is implemented so that we can just ignore calls that don't apply.
        def method_missing(*args)
          log "#{@name} - #{@game_object_id} is ignoring #{args.inspect}"
          log "Consider user #can? instead"
          log caller
          #I don't do nuttin' if I have no reaction to that message
          return nil
        end

        #Compares com_val to game_object_id, then to name, then to alternate names.
        def == comp_val
          if comp_val.nil?
            return false
          elsif comp_val == @game_object_id
            return true
          elsif comp_val.is_a?(String) and comp_val.downcase == @name.downcase
            return true
          elsif comp_val.is_a?(String) and @alt_names.include?(comp_val)
            return true
          elsif comp_val.is_a? Class and self.class == comp_val
            return true
          else
            false
          end
        end

        #Outputs the object and the object name.
        def to_s
          "#{self.class}(#{@name}|#{@game_object_id})"
        end

        #Sets the long description of the object.
        def long_desc= desc
          @long_desc = desc
          
          # If event sourcing is enabled, emit attribute update event
          if defined?(ServerConfig) && ServerConfig[:event_sourcing_enabled] && $manager && defined?(Sequent)
            begin
              command = Aethyr::Core::EventSourcing::UpdateGameObjectAttribute.new(
                id: @game_object_id,
                key: 'long_desc',
                value: desc
              )
              Sequent.command_service.execute_commands(command)
            rescue => e
# Updates the container of the object with event sourcing support.
#
# This method updates the container of the game object (effectively moving it to a new
# location) and, if event sourcing is enabled, emits a GameObjectContainerUpdated event
# to record this change in the event store. This ensures that the change is properly
# tracked and can be replayed if needed.
#
# @param new_container [String] The ID of the new container for the game object
# @return [void]
def container=(new_container)
  old_container = @container
  @container = new_container
          
  # If event sourcing is enabled, emit container update event
  if defined?(ServerConfig) && ServerConfig[:event_sourcing_enabled] && $manager && defined?(Sequent)
    begin
      command = Aethyr::Core::EventSourcing::UpdateGameObjectContainer.new(
        id: @game_object_id,
        container_id: new_container
      )
      Sequent.command_service.execute_commands(command)
    rescue => e
      log "Failed to record event: #{e.message}", Logger::Medium
    end
  end
end
        
# Updates multiple attributes of the object with event sourcing support.
#
# This method updates multiple attributes of the game object at once and, if event
# sourcing is enabled, emits a GameObjectAttributesUpdated event to record these
# changes in the event store. This ensures that the changes are properly tracked
# and can be replayed if needed.
#
# @param attrs_hash [Hash] A hash mapping attribute names to their new values
# @return [void]
def update_attributes(attrs_hash)
  # Update local attributes
  attrs_hash.each do |key, value|
    instance_variable_set("@#{key}", value) if instance_variable_defined?("@#{key}")
    @attributes[key] = value if @attributes
  end
          
  # If event sourcing is enabled, emit attributes update event
  if defined?(ServerConfig) && ServerConfig[:event_sourcing_enabled] && $manager && defined?(Sequent)
    begin
      command = Aethyr::Core::EventSourcing::UpdateGameObjectAttributes.new(
        id: @game_object_id,
        attributes: attrs_hash
      )
      Sequent.command_service.execute_commands(command)
    rescue => e
      log "Failed to record attributes update event: #{e.message}", Logger::Medium
    end
  end
end

# Sets the long description of the object with event sourcing support.
#
# This method updates the long description of the game object and, if event sourcing
# is enabled, emits a GameObjectAttributeUpdated event to record this change in the
# event store. This ensures that the change is properly tracked and can be replayed
# if needed.
#
# @param desc [String] The new long description for the game object
# @return [void]
def long_desc=(desc)
  @long_desc = desc
  
  # If event sourcing is enabled, emit attribute update event
  if defined?(ServerConfig) && ServerConfig[:event_sourcing_enabled] && $manager && defined?(Sequent)
    begin
      command = Aethyr::Core::EventSourcing::UpdateGameObjectAttribute.new(
        id: @game_object_id,
        key: 'long_desc',
        value: desc
      )
      Sequent.command_service.execute_commands(command)
    rescue => e
      log "Failed to record event: #{e.message}", Logger::Medium
    end
  end
end

def long_desc
  if @long_desc == ""
    @short_desc
  else
    @long_desc
  end
end

        #Determines if the object can move.
        def can_move?
          @movable
        end

        #Message when entering from the given direction.
        #If info.entrance_message has not been set and no message is provided, returns a generic movement message.
        #
        #Otherwise, either pass in a message or else info.entrance_message can be used to create custom messages.
        #
        #Use !direction and !name in place of the direction and name.
        #
        #For example, let's say you had a mobile whose generic was 'large bird':
        # "!name flies in from the !direction." => "A large bird flies in from the west."
        #
        #If something more complicated is required, override this method in a subclass.
        def entrance_message direction, message = nil
          if info.entrance_message and not message
            message = info.entrance_message
          end

          case direction
          when "up"
            direction = "up above"
          when "down"
            direction = "below"
          when "in"
            direction = "inside"
          when "out"
            direction = "outside"
          else
            direction = "the " << direction
          end

          if message
            message.gsub(/!direction/, direction).gsub(/!name/, self.name)
          else
            "#{self.name.capitalize} enters from #{direction}."
          end
        end

        #Message when leaving in the given direction. Works the same way as #entrance_message
        def exit_message direction, message = nil
          if info.exit_message and not message
            message = info.exit_message
          end

          case direction
          when "up"
            direction = "go up"
          when "down"
            direction = "go down"
          when "in"
            direction = "go inside"
          when "out"
            direction = "go outside"
          else
            direction = "the " << direction
          end

          if message
            message.gsub(/!direction/, direction).gsub(/!name/, self.name)
          else
            "#{self.name.capitalize} leaves to #{direction}."
          end
        end

        #Returns the name of the object, or, if the name is empty,
        #the article + the generic name of the object.
        def name
          if @name == ""
            @article + " " + @generic
          else
            @name
          end
        end
      end
    end
  end
end
