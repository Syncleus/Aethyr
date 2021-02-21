require "aethyr/core/actions/commands/delete_player"
require "aethyr/core/registry"
require "aethyr/core/input_handlers/admin/admin_handler"

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
              $manager.submit_action(Aethyr::Core::Actions::DeletePlayer::DeletePlayerCommand.new(@player, {:object => object}))
            end
          end

          private

        end
        Aethyr::Extend::HandlerRegistry.register_handler(DeleteplayerHandler)
      end
    end
  end
end
