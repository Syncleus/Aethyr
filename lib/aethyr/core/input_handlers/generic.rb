require "aethyr/core/actions/commands/feel"
require "aethyr/core/actions/commands/listen"
require "aethyr/core/actions/commands/smell"
require "aethyr/core/actions/commands/taste"
require "aethyr/core/actions/commands/write"
require "aethyr/core/actions/commands/deleteme"
require "aethyr/core/actions/commands/who"
require "aethyr/core/actions/commands/date"
require "aethyr/core/actions/commands/time"
require "aethyr/core/actions/commands/fill"
require "aethyr/core/actions/commands/status"
require "aethyr/core/actions/commands/satiety"
require "aethyr/core/actions/commands/health"
require 'aethyr/core/issues'
require "aethyr/core/registry"
require "aethyr/core/input_handlers/command_handler"

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
              $manager.submit_action(Aethyr::Core::Actions::Deleteme::DeletemeCommand.new(@player, {}))
            when /^(health)$/i
              $manager.submit_action(Aethyr::Core::Actions::Health::HealthCommand.new(@player, {}))
            when /^(satiety|hunger)$/i
              $manager.submit_action(Aethyr::Core::Actions::Satiety::SatietyCommand.new(@player, {}))
            when /^(st|stat|status)$/i
              $manager.submit_action(Aethyr::Core::Actions::Status::StatusCommand.new(@player, {}))
            when /^write\s+(.*)/i
              $manager.submit_action(Aethyr::Core::Actions::Write::WriteCommand.new(@player, { :target => $1.strip}))
            when /^(listen)(\s+(.+))?$/i
              $manager.submit_action(Aethyr::Core::Actions::Listen::ListenCommand.new(@player, { :target => $3}))
            when /^(smell|sniff)(\s+(.+))?$/i
              $manager.submit_action(Aethyr::Core::Actions::Smell::SmellCommand.new(@player, { :target => $3}))
            when /^(taste|lick)(\s+(.+))?$/i
              $manager.submit_action(Aethyr::Core::Actions::Taste::TasteCommand.new(@player, { :target => $3}))
            when /^(feel)(\s+(.+))?$/i
              $manager.submit_action(Aethyr::Core::Actions::Feel::FeelCommand.new(@player, { :target => $3}))
            when /^fill\s+(\w+)\s+from\s+(\w+)$/i
              $manager.submit_action(Aethyr::Core::Actions::Fill::FillCommand.new(@player, { :object => $1, :from => $2}))
            when /^who$/i
              $manager.submit_action(Aethyr::Core::Actions::Who::WhoCommand.new(@player, {}))
            when /^time$/i
              $manager.submit_action(Aethyr::Core::Actions::Time::TimeCommand.new(@player, {}))
            when /^date$/i
              $manager.submit_action(Aethyr::Core::Actions::Date::DateCommand.new(@player, {}))
            end
          end

          private
          #Display health.













        end

        Aethyr::Extend::HandlerRegistry.register_handler(GenericHandler)
      end
    end
  end
end
