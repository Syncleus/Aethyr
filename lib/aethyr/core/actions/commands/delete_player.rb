require "aethyr/core/actions/command_action"

module Aethyr
  module Core
    module Actions
      module DeletePlayer
        class DeletePlayerCommand < Aethyr::Extend::CommandAction
          def initialize(actor, **data)
            super(actor, **data)
          end

          def action
            event = @data

            room = $manager.get_object(@player.container)
            player = @player
            name = event.object
            if not $manager.player_exist? name
              player.output "No such player found: #{name}"
              return
            elsif $manager.find name
              player.output "Player is currently logged in. Deletion aborted."
              return
            elsif name == player.name.downcase
              player.output "You cannot delete yourself this way. Use DELETE ME PLEASE instead."
              return
            end

            $manager.delete_player name

            if $manager.find name or $manager.player_exist? name
              player.output "Something went wrong. Player still exists."
            else
              player.output "#{name} deleted."
            end
          end

        end
      end
    end
  end
end
