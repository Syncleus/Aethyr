require "aethyr/core/registry"
require "aethyr/core/commands/admin/admin_handler"

module Aethyr
  module Core
    module Commands
      module Alist
        class AlistHandler < Aethyr::Extend::AdminHandler
          def initialize(player)
            super(player, ["alist"])
          end

          def self.object_added(data)
            return unless data[:game_object].is_a? Player
            data[:game_object].subscribe(AlistHandler.new(data[:game_object]))
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
            when /^help (alist)$/i
              action_help_alist({})
            end
          end

          private
          def action_help_alist(event)
            @player.output <<'EOF'
Sorry no help has been written for this command yet
EOF
          end


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
