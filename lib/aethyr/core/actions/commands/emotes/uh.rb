require "aethyr/core/registry"
require "aethyr/core/commands/emotes/emote_handler"

module Aethyr
  module Core
    module Commands
      module Uh
        class UhHandler < Aethyr::Extend::EmoteHandler

          def self.create_help_entries
            help_entries = []

            command = "uh"
            see_also = nil
            syntax_formats = ["UH"]
            aliases = nil
            content =  <<'EOF'
Please see help for emote instead.
EOF
            help_entries.push(Aethyr::Core::Help::HelpEntry.new(command, content: content, syntax_formats: syntax_formats, see_also: see_also, aliases: aliases))

            return help_entries
          end


          def initialize(player)
            super(player, ["uh"], help_entries: UhHandler.create_help_entries)
          end

          def self.object_added(data)
            super(data, self)
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^(uh)( +([^()]*))?( +((.*)))?$/i
              object = $3
              post = $5
              uh({:object => object, :post => post})
            end
          end

          private
          def uh(event)

            room = $manager.get_object(@player.container)
            player = @player
            make_emote event, player, room do
              no_target do
                to_player "\"Uh...\" you say, staring blankly."
                to_other "With a blank stare, #{player.name} says, \"Uh...\""
              end

              target do
                to_player "With a blank stare at #{target.name}, you say, \"Uh...\""
                to_other "With a blank stare at #{target.name}, #{player.name} says, \"Uh...\""
                to_target "Staring blankly at you, #{player.name} says, \"Uh...\""
              end
            end
          end

        end
        Aethyr::Extend::HandlerRegistry.register_handler(UhHandler)
      end
    end
  end
end
