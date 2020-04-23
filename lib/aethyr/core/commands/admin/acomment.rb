require "aethyr/core/registry"
require "aethyr/core/commands/admin/admin_handler"

module Aethyr
  module Core
    module Commands
      module Acomment
        class AcommentHandler < Aethyr::Extend::AdminHandler
          def initialize(player)
            super(player, ["acomment"])
          end

          def self.object_added(data)
            super(data, self)
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^(acomm|acomment)\s+(.*?)\s+(.*)$/i
              target = $2
              comment = $3
              acomment({:target => target, :comment => comment})
            when /^help (acomment)$/i
              action_help_acomment({})
            end
          end

          private
          def action_help_acomment(event)
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
        Aethyr::Extend::HandlerRegistry.register_handler(AcommentHandler)
      end
    end
  end
end
