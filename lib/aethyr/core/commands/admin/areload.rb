require "aethyr/core/registry"
require "aethyr/core/commands/admin/admin_handler"

module Aethyr
  module Core
    module Commands
      module Areload
        class AreloadHandler < Aethyr::Extend::AdminHandler

          def self.create_help_entries
            help_entries = []

            command = "areload"
            see_also = nil
            syntax_formats = ["ARELOAD [OBJECT]"]
            aliases = nil
            content =  <<'EOF'
Sorry no help has been written for this command yet
EOF
            help_entries.push(Aethyr::Core::Help::HelpEntry.new(command, content: content, syntax_formats: syntax_formats, see_also: see_also, aliases: aliases))

            return help_entries
          end


          def initialize(player)
            super(player, ["areload"], AreloadHandler.create_help_entries)
          end

          def self.object_added(data)
            super(data, self)
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^areload\s+(.*)$/i
              object = $1
              areload({:object => object})
            end
          end

          private
          def areload(event)

            room = $manager.get_object(@player.container)
            player = @player
            begin
              result = load "#{event[:object]}.rb"
              player.output "Reloaded #{event[:object]}: #{result}"
            rescue LoadError
              player.output "Unable to load #{event[:object]}"
            end
          end

        end
        Aethyr::Extend::HandlerRegistry.register_handler(AreloadHandler)
      end
    end
  end
end
