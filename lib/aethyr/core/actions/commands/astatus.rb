require "aethyr/core/actions/command_action"

module Aethyr
  module Core
    module Actions
      module Astatus
        class AstatusCommand < Aethyr::Extend::CommandAction
          def initialize(actor, **data)
            super(actor, **data)
          end

          def action
            event = @data

            room = $manager.get_object(@player.container)
            player = @player
            awho(event, player, room)
            total_objects = $manager.game_objects_count
            player.output("Object Counts:" , true)
            $manager.type_count.each do |obj, count|
              player.output("#{obj}: #{count}", true)
            end
            player.output("Total Objects: #{total_objects}")
          end

        end
      end
    end
  end
end
