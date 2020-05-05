require "aethyr/core/actions/command_action"

module Aethyr
  module Core
    module Actions
      module Who
        class WhoCommand < Aethyr::Core::Actions::CommandAction
          def initialize(actor, **data)
            super(actor, **data)
          end

          def action
            event = @data
            players = $manager.find_all("class", Player)
            output = ["The following people are visiting Aethyr:"]
            players.sort_by {|p| p.name}.each do |playa|
              room = $manager.find playa.container
              output << "#{playa.name} - #{room.name if room}"
            end

            @player.output output
          end
          #Delete your player.
        end
      end
    end
  end
end
