require "aethyr/core/registry"
require "aethyr/core/actions/commands/admin/admin_handler"

module Aethyr
  module Core
    module Commands
      module Deleteplayer
        class DeleteplayerHandler < Aethyr::Extend::AdminHandler

          def self.create_help_entries
            help_entries = []

            command = "deleteplayer"
            see_also = nil
            syntax_formats = ["DELETEPLAYER"]
            aliases = nil
            content =  <<'EOF'
Sorry no help has been written for this command yet
EOF
            help_entries.push(Aethyr::Core::Help::HelpEntry.new(command, content: content, syntax_formats: syntax_formats, see_also: see_also, aliases: aliases))

            return help_entries
          end


          def initialize(player)
            super(player, ["deleteplayer"], help_entries: DeleteplayerHandler.create_help_entries)
          end

          def self.object_added(data)
            super(data, self)
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^deleteplayer\s+(\w+)$/i
              object = $1.downcase
              delete_player({:object => object})
            end
          end

          private
          def delete_player(event)

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
        Aethyr::Extend::HandlerRegistry.register_handler(DeleteplayerHandler)
      end
    end
  end
end
