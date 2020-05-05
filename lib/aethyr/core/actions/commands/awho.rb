require "aethyr/core/actions/command_action"

module Aethyr
  module Core
    module Actions
      module Awho
        class AwhoCommand < Aethyr::Core::Actions::CommandAction
          def initialize(actor, **data)
            super(actor, **data)
          end

          def action
            event = @data

            room = $manager.get_object(@player.container)
            player = @player
            players = $manager.find_all('class', Player)

            names = []
            players.each do |playa|
              names << playa.name
            end

            player.output('Players currently online:', true)
            player.output(names.join(', '))
          end

        end
      end
    end
  end
end
