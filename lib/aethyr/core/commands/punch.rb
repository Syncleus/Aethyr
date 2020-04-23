require "aethyr/core/registry"
require "aethyr/core/commands/command_handler"

module Aethyr
  module Core
    module Commands
      module Punch
        class PunchHandler < Aethyr::Extend::CommandHandler
          def initialize(player)
            super(player, ["punch"])
          end

          def self.object_added(data)
            super(data, klass: self)
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^punch$/i
              punch({})
            when /^punch\s+(.*)$/i
              target = $1
              punch({:target => target})
            when /^help (punch)$/i
              action_help_punch({})
            end
          end

          private
          def action_help_punch(event)
            @player.output <<'EOF'
Sorry no help has been written for this command yet
EOF
          end


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
