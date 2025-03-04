require "aethyr/core/actions/commands/command_action"

module Aethyr
  module Core
    module Actions
      module Areload
        class AreloadCommand < Aethyr::Extend::CommandAction
          def initialize(actor, **data)
            super(actor, **data)
          end

          def action
            

            room = $manager.get_object(@player.container)
            player = @player
            begin
              result = load "#{self[:object]}.rb"
              player.output "Reloaded #{self[:object]}: #{result}"
            rescue LoadError
              player.output "Unable to load #{self[:object]}"
            end
          end

        end
      end
    end
  end
end
