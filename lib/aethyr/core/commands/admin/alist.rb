require "aethyr/core/registry"
require "aethyr/core/commands/admin/admin_handler"

module Aethyr
  module Core
    module Commands
      module Alist
        class AlistHandler < Aethyr::Extend::AdminHandler

          def self.create_help_entries
            help_entries = []

            command = "alist"
            see_also = nil
            syntax_formats = ["ALIST [ATTRIB] [QUERY]"]
            aliases = nil
            content =  <<'EOF'
Sorry no help has been written for this command yet
EOF
            help_entries.push(Aethyr::Core::Help::HelpEntry.new(command, content: content, syntax_formats: syntax_formats, see_also: see_also, aliases: aliases))

            return help_entries
          end


          def initialize(player)
            super(player, ["alist"], help_entries: AlistHandler.create_help_entries)
          end

          def self.object_added(data)
            super(data, self)
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^alist$/i
              alist({})
            when /^alist\s+(@\w+|class)\s+(.*)/i
              attrib = $2
              match = $1
              alist({:attrib => attrib, :match => match})
            end
          end

          private
          def alist(event)

            room = $manager.get_object(@player.container)
            player = @player
            objects = nil
            if event[:match].nil?
              objects = $manager.find_all("class", :GameObject)
            else
              objects = $manager.find_all(event[:match], event[:attrib])
            end

            if objects.empty?
              player.output "Nothing like that to list!"
            else
              output = []
              objects.each do |o|
                output << "\t" + o.to_s
              end

              output = output.join("\n")

              player.output(output)
            end
          end

        end
        Aethyr::Extend::HandlerRegistry.register_handler(AlistHandler)
      end
    end
  end
end
