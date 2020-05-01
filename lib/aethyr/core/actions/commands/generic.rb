require 'aethyr/core/issues'
require "aethyr/core/registry"
require "aethyr/core/actions/commands/command_handler"

module Aethyr
  module Core
    module Commands
      module Generic
        class GenericHandler < Aethyr::Extend::CommandHandler

          def self.create_help_entries
            help_entries = []

            command = "health"
            see_also = ["STATUS", "HUNGER"]
            syntax_formats = ["HEALTH"]
            aliases = nil
            content =  <<'EOF'
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

EOF
            help_entries.push(Aethyr::Core::Help::HelpEntry.new(command, content: content, syntax_formats: syntax_formats, see_also: see_also, aliases: aliases))



            command = "satiety"
            see_also = ["STAT", "HEALTH"]
            syntax_formats = ["HUNGER", "SATIETY"]
            aliases = nil
            content =  <<'EOF'
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

EOF
            help_entries.push(Aethyr::Core::Help::HelpEntry.new(command, content: content, syntax_formats: syntax_formats, see_also: see_also, aliases: aliases))



            command = "status"
            see_also = ["INVENTORY", "HUNGER", "HEALTH"]
            syntax_formats = ["STATUS", "STAT", "ST"]
            aliases = nil
            content =  <<'EOF'
Shows your current health, hunger/satiety, and position.

EOF
            help_entries.push(Aethyr::Core::Help::HelpEntry.new(command, content: content, syntax_formats: syntax_formats, see_also: see_also, aliases: aliases))



            command = "fill"
            see_also = nil
            syntax_formats = ["FILL [container] FROM [source]"]
            aliases = nil
            content =  <<'EOF'
Fill a container from a source

EOF
            help_entries.push(Aethyr::Core::Help::HelpEntry.new(command, content: content, syntax_formats: syntax_formats, see_also: see_also, aliases: aliases))



            command = "date_time"
            see_also = nil
            syntax_formats = ["DATE"]
            aliases = nil
            content =  <<'EOF'
Date and Time

        TIME

Shows the current date and time in Aethyr. Not completely done yet, but it is a first step.

EOF
            help_entries.push(Aethyr::Core::Help::HelpEntry.new(command, content: content, syntax_formats: syntax_formats, see_also: see_also, aliases: aliases))



            command = "who"
            see_also = nil
            syntax_formats = ["WHO"]
            aliases = nil
            content =  <<'EOF'
This will list everyone else who is currently in Aethyr and where they happen to be at the moment.

EOF
            help_entries.push(Aethyr::Core::Help::HelpEntry.new(command, content: content, syntax_formats: syntax_formats, see_also: see_also, aliases: aliases))



            command = "deleteme"
            see_also = nil
            syntax_formats = ["DELETE ME PLEASE"]
            aliases = nil
            content =  <<'EOF'
Deleting Your Character

In case you ever need to do so, you can remove your character from the game. Quite permanently. You will need to enter your password as confirmation and that's it. You will be wiped out of time and memory.

EOF
            help_entries.push(Aethyr::Core::Help::HelpEntry.new(command, content: content, syntax_formats: syntax_formats, see_also: see_also, aliases: aliases))



            command = "write"
            see_also = nil
            syntax_formats = ["WRITE [target]"]
            aliases = nil
            content =  <<'EOF'
Write something on the specified target.

EOF
            help_entries.push(Aethyr::Core::Help::HelpEntry.new(command, content: content, syntax_formats: syntax_formats, see_also: see_also, aliases: aliases))



            command = "taste"
            see_also = nil
            syntax_formats = ["TASTE [target]"]
            aliases = nil
            content =  <<'EOF'
Taste the specified target.

EOF
            help_entries.push(Aethyr::Core::Help::HelpEntry.new(command, content: content, syntax_formats: syntax_formats, see_also: see_also, aliases: aliases))



            command = "smell"
            see_also = nil
            syntax_formats = ["SMELL [target]"]
            aliases = nil
            content =  <<'EOF'
Smell the specified target.

EOF
            help_entries.push(Aethyr::Core::Help::HelpEntry.new(command, content: content, syntax_formats: syntax_formats, see_also: see_also, aliases: aliases))



            command = "listen"
            see_also = nil
            syntax_formats = ["LISTEN [target]"]
            aliases = nil
            content =  <<'EOF'
Listen to the specified target.

EOF
            help_entries.push(Aethyr::Core::Help::HelpEntry.new(command, content: content, syntax_formats: syntax_formats, see_also: see_also, aliases: aliases))



            command = "feel"
            see_also = nil
            syntax_formats = ["FEEL [target]"]
            aliases = nil
            content =  <<'EOF'
Feel the specified target.

EOF
            help_entries.push(Aethyr::Core::Help::HelpEntry.new(command, content: content, syntax_formats: syntax_formats, see_also: see_also, aliases: aliases))

            return help_entries
          end


          def initialize(player)
            super(player, ['date', 'delete', 'feel', 'taste', 'smell', 'sniff', 'lick', 'listen', 'health', 'hunger', 'satiety', 'shut', 'status', 'stat', 'st', 'time', 'typo', 'who', 'write'], help_entries: GenericHandler.create_help_entries)
          end

          def self.object_added(data)
            super(data, self)
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
            end
          end

          private
          #Display health.
          def action_health(event)
            @player.output "You are #{@player.health}."
          end
          #Display hunger.
          def action_satiety(event)
            @player.output "You are #{@player.satiety}."
          end
          #Display status.
          def action_status(event)
            @player.output("You are #{@player.health}.")
            @player.output("You are feeling #{@player.satiety}.")
            @player.output "You are currently #{@player.pose || 'standing up'}."
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
          #Display time.
          def action_time(event)
            @player.output $manager.time
          end

          #Display date.
          def action_date(event)
            @player.output $manager.date
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
        end

        Aethyr::Extend::HandlerRegistry.register_handler(GenericHandler)
      end
    end
  end
end
