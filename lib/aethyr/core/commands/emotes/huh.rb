require "aethyr/core/registry"
require "aethyr/core/commands/emotes/emote_handler"

module Aethyr
  module Core
    module Commands
      module Huh
        class HuhHandler < Aethyr::Extend::EmoteHandler

          def self.create_help_entries
            help_entries = []

            command = "huh"
            see_also = nil
            syntax_formats = ["HUH"]
            aliases = nil
            content =  <<'EOF'
Please see help for emote instead.
EOF
            help_entries.push(Aethyr::Core::Help::HelpEntry.new(command, content: content, syntax_formats: syntax_formats, see_also: see_also, aliases: aliases))

            return help_entries
          end


          def initialize(player)
            super(player, ["huh"], HuhHandler.create_help_entries)
          end

          def self.object_added(data)
            super(data, self)
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^(huh)( +([^()]*))?( +((.*)))?$/i
              object = $3
              post = $5
              huh({:object => object, :post => post})
            end
          end

          private
          def huh(event)

            room = $manager.get_object(@player.container)
            player = @player
            make_emote event, player, room do

              no_target do
                to_player  "\"Huh?\" you ask, confused."
                to_other "#{player.name} ask, \"Huh?\" and looks confused."
              end

              self_target do
                player.output "Well, huh!"
              end

              target do
                to_player "\"Huh?\" you ask #{event.target.name}."
                to_target "#{player.name} asks, \"Huh?\""
                to_other "#{player.name} asks #{event.target.name}, \"Huh?\""
              end
            end

          end

        end
        Aethyr::Extend::HandlerRegistry.register_handler(HuhHandler)
      end
    end
  end
end
