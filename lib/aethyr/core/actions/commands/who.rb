require "aethyr/core/actions/commands/command_action"

module Aethyr
  module Core
    module Actions
      module Who
        class WhoCommand < Aethyr::Extend::CommandAction
          def initialize(actor, **data)
            super(actor, **data)
          end

          def action

            players = $manager.find_all("class", Player)
            output = ["The following people are visiting Aethyr:"]
            players.sort_by {|p| p.name}.each do |playa|
              room = $manager.find playa.container
              output << "#{playa.name} - #{room.name if room}"
            end

            self[:agent].output output
          end
          #Delete your player.
        end
      end
    end
  end
end
