require "aethyr/core/actions/commands/aset"
require "aethyr/core/registry"
require "aethyr/core/input_handlers/admin/admin_handler"

module Aethyr
  module Core
    module Commands
      module Aset
        class AsetHandler < Aethyr::Extend::AdminHandler

          def self.create_help_entries
            help_entries = []

            command = "aset"
            see_also = nil
            syntax_formats = ["ASET [OBJECT] @[ATTRIBUTE] [VALUE]"]
            aliases = nil
            content =  <<'EOF'
Sorry no help has been written for this command yet
EOF
            help_entries.push(Aethyr::Core::Help::HelpEntry.new(command, content: content, syntax_formats: syntax_formats, see_also: see_also, aliases: aliases))

            return help_entries
          end


          def initialize(player)
            super(player, ["aset", "aset!"], help_entries: AsetHandler.create_help_entries)
          end

          def self.object_added(data)
            super(data, self)
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^aset\s+(.+?)\s+(@\w+|smell|feel|texture|taste|sound|listen)\s+(.*)$/i
              object = $1
              attribute = $2
              value = $3
              $manager.submit_action(Aethyr::Core::Actions::Aset::AsetCommand.new(@player, :object => object, :attribute => attribute, :value => value))
            when /^aset!\s+(.+?)\s+(@\w+|smell|feel|texture|taste|sound|listen)\s+(.*)$/i
              object = $1
              attribute = $2
              value = $3
              force = true
              $manager.submit_action(Aethyr::Core::Actions::Aset::AsetCommand.new(@player, :object => object, :attribute => attribute, :value => value, :force => force))
            when /^aset!\s+(.+?)\s+(@\w+|smell|feel|texture|taste|sound|listen)\s+(.*)$/i
              object = $1
              attribute = $2
              value = $3
              force = true
              $manager.submit_action(Aethyr::Core::Actions::Aset::AsetCommand.new(@player, :object => object, :attribute => attribute, :value => value, :force => force))
            end
          end

          private

        end
        Aethyr::Extend::HandlerRegistry.register_handler(AsetHandler)
      end
    end
  end
end
