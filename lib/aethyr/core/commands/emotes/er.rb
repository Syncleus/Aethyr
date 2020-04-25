require "aethyr/core/registry"
require "aethyr/core/commands/emotes/emote_handler"

module Aethyr
  module Core
    module Commands
      module Er
        class ErHandler < Aethyr::Extend::EmoteHandler

          def self.create_help_entries
            help_entries = []

            command = "er"
            see_also = nil
            syntax_formats = ["ER"]
            aliases = nil
            content =  <<'EOF'
Please see help for emote instead.
EOF
            help_entries.push(Aethyr::Core::Help::HelpEntry.new(command, content: content, syntax_formats: syntax_formats, see_also: see_also, aliases: aliases))

            return help_entries
          end


          def initialize(player)
            super(player, ["er"], ErHandler.create_help_entries)
          end

          def self.object_added(data)
            super(data, self)
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^(er)( +([^()]*))?( +((.*)))?$/i
              object = $3
              post = $5
              er({:object => object, :post => post})
            end
          end

          private
          def er(event)

            room = $manager.get_object(@player.container)
            player = @player
            make_emote event, player, room do
              no_target do
                to_player "With a look of uncertainty, you say, \"Er...\""
                to_other "With a look of uncertainty, #{player.name} says, \"Er...\""
              end

              target do
                to_player "Looking at #{target.name} uncertainly, you say, \"Er...\""
                to_other "Looking at #{target.name} uncertainly, #{player.name} says, \"Er...\""
                to_target "Looking at you uncertainly, #{player.name} says, \"Er...\""
              end
            end
          end

        end
        Aethyr::Extend::HandlerRegistry.register_handler(ErHandler)
      end
    end
  end
end
