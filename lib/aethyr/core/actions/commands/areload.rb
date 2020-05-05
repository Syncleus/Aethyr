require "aethyr/core/actions/command_action"

module Aethyr
  module Core
    module Actions
      module Areload
        class AreloadCommand < Aethyr::Core::Actions::CommandAction
          def initialize(actor, **data)
            super(actor, **data)
          end

          def action
            event = @data

            room = $manager.get_object(@player.container)
            player = @player
            begin
              result = load "#{event[:object]}.rb"
              player.output "Reloaded #{event[:object]}: #{result}"
            rescue LoadError
              player.output "Unable to load #{event[:object]}"
            end
          end

        end
      end
    end
  end
end
