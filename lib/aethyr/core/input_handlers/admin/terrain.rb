require "aethyr/core/actions/commands/terrain"
require "aethyr/core/registry"
require "aethyr/core/input_handlers/admin/admin_handler"

module Aethyr
  module Core
    module Commands
      module Terrain
        class TerrainHandler < Aethyr::Extend::AdminHandler

          def self.create_help_entries
            help_entries = []

            command = "terrain"
            see_also = nil
            syntax_formats = ["TERRAIN AREA [TYPE]", "TERRAIN HERE TYPE [TYPE]", "TERRAIN HERE (INDOORS|WATER|UNDERWATER) (YES|NO)"]
            aliases = nil
            content =  <<'EOF'
Sorry no help has been written for this command yet
EOF
            help_entries.push(Aethyr::Core::Help::HelpEntry.new(command, content: content, syntax_formats: syntax_formats, see_also: see_also, aliases: aliases))

            return help_entries
          end


          def initialize(player)
            super(player, ["terrain"], help_entries: TerrainHandler.create_help_entries)
          end

          def self.object_added(data)
            super(data, self)
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^terrain\s+area\s+(.*)$/i
              target = "area"
              value = $1
              $manager.submit_action(Aethyr::Core::Actions::Terrain::TerrainCommand.new(@player, {:target => target, :value => value}))
            when /^terrain\s+(room|here)\s+(type|indoors|underwater|water)\s+(.*)$/
              target = "room"
              setting = $2.downcase
              value = $3
              $manager.submit_action(Aethyr::Core::Actions::Terrain::TerrainCommand.new(@player, {:target => target, :setting => setting, :value => value}))
            end
          end

          private

        end
        Aethyr::Extend::HandlerRegistry.register_handler(TerrainHandler)
      end
    end
  end
end
