require 'aethyr/core/issues'
require "aethyr/core/registry"
require "aethyr/core/commands/command_handler"

module Aethyr
  module Core
    module Commands
      module Generic
        class GenericHandler < Aethyr::Extend::CommandHandler
          def initialize(player)
            super(player, ['date', 'delete', 'feel', 'taste', 'smell', 'sniff', 'lick', 'listen', 'health', 'hunger', 'satiety', 'shut', 'status', 'stat', 'st', 'time', 'typo', 'who', 'write'])
          end

          def self.object_added(data)
            return unless data[:game_object].is_a? Player
            data[:game_object].subscribe(GenericHandler.new(data[:game_object]))
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^delete me please$/i
              action_deleteme({})
            when /^(health)$/i
              action_health({})
            when /^(satiety|hunger)$/i
              action_satiety({})
            when /^(st|stat|status)$/i
              action_status({})
            when /^write\s+(.*)/i
              action_write({ :target => $1.strip})
            when /^(listen)(\s+(.+))?$/i
              action_listen({ :target => $3})
            when /^(smell|sniff)(\s+(.+))?$/i
              action_smell({ :target => $3})
            when /^(taste|lick)(\s+(.+))?$/i
              action_taste({ :target => $3})
            when /^(feel)(\s+(.+))?$/i
              action_feel({ :target => $3})
            when /^fill\s+(\w+)\s+from\s+(\w+)$/i
              action_fill({ :object => $1,
                :from => $2})
            when /^who$/i
              action_who({})
            when /^time$/i
              action_time({})
            when /^date$/i
              action_date({})
            when /^help (delete|delete me please)$/i
              action_help_deleteme({})
            when /^help health$/i
              action_help_health({})
            when /^help (satiety|hunger)$/i
              action_help_satiety({})
            when /^help (st|stat|status)$/i
              action_help_status({})
            when /^help write/i
              action_help_write({ :target => $1.strip})
            when /^help listen$/i
              action_help_listen({ :target => $3})
            when /^help (smell|sniff)$/i
              action_help_smell({ :target => $3})
            when /^help (taste|lick)$/i
              action_help_taste({ :target => $3})
            when /^help feel$/i
              action_help_feel({ :target => $3})
            when /^help who$/i
              action_help_who({})
            when /^help (date|time)$/i
              action_help_date_time({})
            when /^help fill$/i
              action_help_fill({})
            end
          end

          private
          #Display health.
          def action_health(event)
            @player.output "You are #{@player.health}."
          end
          
          def action_help_health(event)
            @player.output <<'EOF'
Command: Health
Syntax: HEALTH

Shows you how healthy you are.

You can be:
	at full health
	a bit bruised
	a little beat up
	slightly injured
	quite injured
	slightly wounded
	wounded in several places
	heavily wounded
	bleeding profusely and in serious pain
	nearly dead
	dead

See also: STATUS, HUNGER

EOF
          end

          #Display hunger.
          def action_satiety(event)
            @player.output "You are #{@player.satiety}."
          end
          
          def action_help_satiety(event)
            @player.output <<'EOF'
Command: Hunger (or Satiety)
Syntax: HUNGER
Syntax: SATIETY

Shows you how hungry you are.

You can be:
	completely stuffed
	full and happy
	full and happy
	satisfied
	not hungry
	slightly hungry
	slightly hungry
	peckish
	hungry
	very hungry
	famished
	starving
	literally dying of hunger

See also: STAT HEALTH

EOF
          end

          #Display status.
          def action_status(event)
            @player.output("You are #{@player.health}.", true)
            @player.output("You are feeling #{@player.satiety}.", true)
            @player.output "You are currently #{@player.pose || 'standing up'}."
          end
          
          def action_help_status(event)
            @player.output <<'EOF'
Command: Status
Syntax: STATUS
Syntax: STAT
Syntax: ST

Shows your current health, hunger/satiety, and position.

See also: INVENTORY, HUNGER, HEALTH

EOF
          end

          #Fill something.
          def action_fill(event)
            room = $manager.get_object(@player.container)
            object = @player.search_inv(event[:object]) || room.find(event[:object])
            from = @player.search_inv(event[:from]) || room.find(event[:from])

            if object.nil?
              @player.output("What would you like to fill?")
              return
            elsif not object.is_a? LiquidContainer
              @player.output("You cannot fill #{object.name} with liquids.")
              return
            elsif from.nil?
              @player.output "There isn't any #{event[:from]} around here."
              return
            elsif not from.is_a? LiquidContainer
              @player.output "You cannot fill #{object.name} from #{from.name}."
              return
            elsif from.empty?
              @player.output "That #{object.generic} is empty."
              return
            elsif object.full?
              @player.output("That #{object.generic} is full.")
              return
            elsif object == from
              @player.output "Quickly flipping #{object.name} upside-down then upright again, you manage to fill it from itself."
              return
            end
          end
          
          def action_help_fill(event)
            @player.output <<'EOF'
Command: Fill
Syntax: FILL [container] FROM [source]

Fill a container from a source

EOF
          end

          #Display time.
          def action_time(event)
            @player.output $manager.time
          end

          #Display date.
          def action_date(event)
            @player.output $manager.date
          end
          
          def action_help_date_time(event)
            @player.output <<'EOF'
Date and Time

Syntax: DATE
        TIME

Shows the current date and time in Aethyr. Not completely done yet, but it is a first step.

EOF
          end

          #Show who is in the game.
          def action_who(event)
            players = $manager.find_all("class", Player)
            output = ["The following people are visiting Aethyr:"]
            players.sort_by {|p| p.name}.each do |playa|
              room = $manager.find playa.container
              output << "#{playa.name} - #{room.name if room}"
            end

            @player.output output
          end
          
          def action_help_who(event)
            @player.output <<'EOF'
Command: Who
Syntax: WHO

This will list everyone else who is currently in Aethyr and where they happen to be at the moment.

EOF
          end

          #Delete your player.
          def action_deleteme(event)
            if event[:password]
              if $manager.check_password(@player.name, event[:password])
                @player.output "This character #{@player.name} will no longer exist."
                @player.quit
                $manager.delete_player(@player.name)
              else
                @player.output "That password is incorrect. You are allowed to continue existing."
              end
            else
              @player.output "To confirm your deletion, please enter your password:"
              @player.io.echo_off
              @player.expect do |password|
                @player.io.echo_on
                event[:password] = password
                Generic.deleteme(event)
              end
            end
          end
          
          def action_help_deleteme(event)
            @player.output <<'EOF'
Deleting Your Character

Syntax: DELETE ME PLEASE

In case you ever need to do so, you can remove your character from the game. Quite permanently. You will need to enter your password as confirmation and that's it. You will be wiped out of time and memory.

EOF
          end

          #Write something.
          def action_write(event)
            object = @player.search_inv(event[:target])

            if object.nil?
              @player.output "What do you wish to write on?"
              return
            end

            if not object.info.writable
              @player.output "You cannot write on #{object.name}."
              return
            end

            @player.output "You begin to write on #{object.name}."

            @player.editor(object.readable_text || [], 100) do |data|
              unless data.nil?
                object.readable_text = data
              end
              @player.output "You finish your writing."
            end
          end
          
          def action_help_write(event)
            @player.output <<'EOF'
Command: Write
Syntax: WRITE [target]

Write something on the specified target.

EOF
          end

          def action_taste(event)
            room = $manager.get_object(@player.container)
            object = @player.search_inv(event[:target]) || room.find(event[:target])

            if object == @player or event[:target] == "me"
              @player.output "You covertly lick yourself.\nHmm, not bad."
              return
            elsif object.nil?
              @player.output "What would you like to taste?"
              return
            end

            event[:target] = object
            event[:to_player] = "Sticking your tongue out hesitantly, you taste #{object.name}. "
            if object.info.taste.nil? or object.info.taste == ""
              event[:to_player] << "#{object.pronoun.capitalize} does not taste that great, but has no particular flavor."
            else
              event[:to_player] << object.info.taste
            end
            event[:to_target] = "#{@player.name} licks you, apparently in an attempt to find out your flavor."
            event[:to_other] = "#{@player.name} hesitantly sticks out #{@player.pronoun(:possessive)} tongue and licks #{object.name}."
            room.out_event event
          end
          
          def action_help_taste(event)
            @player.output <<'EOF'
Command: Taste
Syntax: TASTE [target]

Taste the specified target.

EOF
          end

          def action_smell(event)
            room = $manager.get_object(@player.container)
            if event[:target].nil?
              if room.info.smell
                event[:to_player] = "You sniff the air. #{room.info.smell}."
              else
                event[:to_player] = "You sniff the air, but detect no unusual aromas."
              end
              event[:to_other] = "#{@player.name} sniffs the air."
              room.out_event event
              return
            end

            object = @player.search_inv(event[:target]) || room.find(event[:target])

            if object == @player or event[:target] == "me"
              event[:target] = @player
              event[:to_player] = "You cautiously sniff your armpits. "
              if rand > 0.6
                event[:to_player] << "Your head snaps back from the revolting stench coming from beneath your arms."
                event[:to_other] = "#{@player.name} sniffs #{@player.pronoun(:possessive)} armpits, then recoils in horror."
              else
                event[:to_player] << "Meh, not too bad."
                event[:to_other] = "#{@player.name} sniffs #{@player.pronoun(:possessive)} armpits, then shrugs, apparently unconcerned with #{@player.pronoun(:possessive)} current smell."
              end
              room.out_event event
              return
            elsif object.nil?
              @player.output "What are you trying to smell?"
              return
            end

            event[:target] = object
            event[:to_player] = "Leaning in slightly, you sniff #{object.name}. "
            if object.info.smell.nil? or object.info.smell == ""
              event[:to_player] << "#{object.pronoun.capitalize} has no particular aroma."
            else
              event[:to_player] << object.info.smell
            end
            event[:to_target] = "#{@player.name} sniffs you curiously."
            event[:to_other] = "#{@player.name} thrusts #{@player.pronoun(:possessive)} nose at #{object.name} and sniffs."
            room.out_event event
          end
          
          def action_help_smell(event)
            @player.output <<'EOF'
Command: Smell
Syntax: SMELL [target]

Smell the specified target.

EOF
          end

          def action_listen(event)
            room = $manager.get_object(@player.container)
            if event[:target].nil?
              event[:target] = room
              if room.info.sound
                event[:to_player] = "You listen carefully. #{room.info.sound}."
              else
                event[:to_player] = "You listen carefully but hear nothing unusual."
              end
              event[:to_other] = "A look of concentration forms on #{@player.name}'s face as #{@player.pronoun} listens intently."
              room.out_event event
              return
            end

            object = @player.search_inv(event[:target]) || room.find(event[:target])

            if object == @player or event[:target] == "me"
              @player.output "Listening quietly, you can faintly hear your pulse."
              return
            elsif object.nil?
              @player.output "What would you like to listen to?"
              return
            end

            event[:target] = object
            event[:to_player] = "You bend your head towards #{object.name}. "
            if object.info.sound.nil? or object.info.sound == ""
              event[:to_player] << "#{object.pronoun.capitalize} emits no unusual sounds."
            else
              event[:to_player] << object.info.sound
            end
            event[:to_target] = "#{@player.name} listens to you carefully."
            event[:to_other] = "#{@player.name} bends #{@player.pronoun(:possessive)} head towards #{object.name} and listens."
            room.out_event event
          end
          
          def action_help_listen(event)
            @player.output <<'EOF'
Command: Listen
Syntax: LISTEN [target]

Listen to the specified target.

EOF
          end

          def action_feel(event)
            room = $manager.get_object(@player.container)
            object = @player.search_inv(event[:target]) || room.find(event[:target])

            if object == @player or event[:target] == "me"
              @player.output "You feel fine."
              return
            elsif object.nil?
              @player.output "What would you like to feel?"
              return
            end

            event[:target] = object
            event[:to_player] = "You reach out your hand and gingerly feel #{object.name}. "
            if object.info.texture.nil? or object.info.texture == ""
              event[:to_player] << "#{object.pronoun(:possessive).capitalize} texture is what you would expect."
            else
              event[:to_player] << object.info.texture
            end
            event[:to_target] = "#{@player.name} reaches out a hand and gingerly touches you."
            event[:to_other] = "#{@player.name} reaches out #{@player.pronoun(:possessive)} hand and touches #{object.name}."
            room.out_event event
          end
          
          def action_help_feel(event)
            @player.output <<'EOF'
Command: Feel
Syntax: FEEL [target]

Feel the specified target.

EOF
          end
        end
        
        Aethyr::Extend::HandlerRegistry.register_handler(GenericHandler)
      end
    end
  end
end