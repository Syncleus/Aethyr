require "aethyr/core/registry"
require "aethyr/core/commands/command_handler"

module Aethyr
  module Core
    module Commands
      module Kick
        class KickHandler < Aethyr::Extend::CommandHandler
          def initialize(player)
            super(player, ["kick"])
          end

          def self.object_added(data)
            super(data, klass: self)
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^kick$/i
              kick({})
            when /^kick\s+(.*)$/i
              target = $1
              kick({:target => target})
            when /^help (kick)$/i
              action_help_kick({})
            end
          end

          private
          def action_help_kick(event)
            @player.output <<'EOF'
Sorry no help has been written for this command yet
EOF
          end


          def kick(event)

            room = $manager.get_object(@player.container)
            player = @player
            return if not Combat.ready? player

            target = (event.target && room.find(event.target)) || room.find(player.last_target)

            if target.nil?
              player.output "Who are you trying to attack?"
              return
            else
              return unless Combat.valid_target? player, target
            end

            player.last_target = target.goid

            event.target = target

            event[:to_other] = "#{player.name} kicks #{player.pronoun(:possessive)} foot out at #{target.name}."
            event[:to_target] = "#{player.name} kicks #{player.pronoun(:possessive)} foot at you."
            event[:to_player] = "You balance carefully and kick your foot out towards #{target.name}."
            event[:blockable] = true

            player.balance = false
            player.info.in_combat = true
            target.info.in_combat = true

            room.out_event event

            event[:action] = :martial_hit
            event[:combat_action] = :kick
            event[:to_other] = "#{player.name} kicks #{target.name} with considerable violence."
            event[:to_target] = "#{player.name} kicks you rather violently."
            event[:to_player] = "Your kick makes good contact with #{target.name}."

            Combat.future_event event
          end

        end
        Aethyr::Extend::HandlerRegistry.register_handler(KickHandler)
      end
    end
  end
end
