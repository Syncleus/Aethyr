require "aethyr/core/registry"
require "aethyr/core/commands/command_handler"

module Aethyr
  module Core
    module Commands
      module Acportal
        class AcportalHandler < Aethyr::Extend::CommandHandler
          def initialize(player)
            super(player, ["acportal"])
          end

          def self.object_added(data)
            return unless data[:game_object].is_a? Player
            data[:game_object].subscribe(AcportalHandler.new(data[:game_object]))
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^acportal(\s+(jump|climb|crawl|enter))?(\s+(.*))?$/i
              object = "portal"
              alt_names = []
              portal_action = $2
              args = [$4]
              acportal({:object => object, :alt_names => alt_names, :portal_action => portal_action, :args => args})
            when /^help (acportal)$/i
              action_help_acportal({})
            end
          end

          private
          def action_help_acportal(event)
            @player.output <<'EOF'
Sorry no help has been written for this command yet
EOF
          end


          def acportal(event)

            room = $manager.get_object(@player.container)
            player = @player
            object = Admin.acreate(event, player, room)
            if event[:portal_action] and event[:portal_action].downcase != "enter"
              object.info.portal_action = event[:portal_action].downcase.to_sym
            end
          end

        end
        Aethyr::Extend::HandlerRegistry.register_handler(AcportalHandler)
      end
    end
  end
end
