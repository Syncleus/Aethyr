require "aethyr/core/registry"
require "aethyr/core/actions/commands/command_handler"

module Aethyr
  module Core
    module Commands
      module Punch
        class PunchHandler < Aethyr::Extend::CommandHandler

          def self.create_help_entries
            help_entries = []

            command = "punch"
            see_also = nil
            syntax_formats = ["PUNCH"]
            aliases = nil
            content =  <<'EOF'
Sorry no help has been written for this command yet
EOF
            help_entries.push(Aethyr::Core::Help::HelpEntry.new(command, content: content, syntax_formats: syntax_formats, see_also: see_also, aliases: aliases))

            return help_entries
          end


          def initialize(player)
            super(player, ["punch"], help_entries: PunchHandler.create_help_entries)
          end

          def self.object_added(data)
            super(data, self)
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^punch$/i
              punch({})
            when /^punch\s+(.*)$/i
              target = $1
              punch({:target => target})
            end
          end

          private
          def punch(event)

            room = $manager.get_object(@player.container)
            player = @player
            return unless Combat.ready? player

            target = (event.target && room.find(event.target)) || room.find(player.last_target)

            if target.nil?
              player.output "Who are you trying to attack?"
              return
            else
              return unless Combat.valid_target? player, target
            end

            player.last_target = target.goid

            event.target = target

            event[:to_other] = "#{player.name} swings #{player.pronoun(:possessive)} clenched fist at #{target.name}."
            event[:to_target] = "#{player.name} swings #{player.pronoun(:possessive)} fist straight towards your face."
            event[:to_player] = "You clench your hand into a fist and swing it at #{target.name}."
            event[:blockable] = true

            player.balance = false
            player.info.in_combat = true
            target.info.in_combat = true

            room.out_event event

            event[:action] = :martial_hit
            event[:combat_action] = :punch
            event[:to_other] = "#{player.name} punches #{target.name} directly in the face."
            event[:to_target] = "You stagger slightly as #{player.name} punches you in the face."
            event[:to_player] = "Your fist lands squarely in #{target.name}'s face."

            Combat.future_event event
          end

        end
        Aethyr::Extend::HandlerRegistry.register_handler(PunchHandler)
      end
    end
  end
end
