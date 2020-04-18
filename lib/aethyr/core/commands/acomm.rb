require "aethyr/core/registry"
require "aethyr/core/commands/command_handler"

module Aethyr
  module Core
    module Commands
      module Acomm
        class AcommHandler < Aethyr::Extend::CommandHandler
          def initialize(player)
            super(player, ["acomm"])
          end

          def self.object_added(data)
            return unless data[:game_object].is_a? Player
            data[:game_object].subscribe(AcommHandler.new(data[:game_object]))
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^(acomm|acomment)\s+(.*?)\s+(.*)$/i
              target = $2
              comment = $3
              acomment({:target => target, :comment => comment})
            when /^help (acomm)$/i
              action_help_acomm({})
            end
          end

          private
          def action_help_acomm(event)
            @player.output <<'EOF'
Sorry no help has been written for this command yet
EOF
          end


          def acomment(event)

            room = $manager.get_object(@player.container)
            player = @player
            object = find_object(event[:target], event)
            if object.nil?
              player.output "Cannot find:#{event[:target]}"
              return
            end

            object.comment = event[:comment]
            player.output "Added comment: '#{event[:comment]}'\nto#{object}"
          end

        end
        Aethyr::Extend::HandlerRegistry.register_handler(AcommHandler)
      end
    end
  end
end
