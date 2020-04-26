require "aethyr/core/registry"
require "aethyr/core/commands/emotes/emote_handler"

module Aethyr
  module Core
    module Commands
      module Cry
        class CryHandler < Aethyr::Extend::EmoteHandler

          def self.create_help_entries
            help_entries = []

            command = "cry"
            see_also = nil
            syntax_formats = ["CRY"]
            aliases = nil
            content =  <<'EOF'
Please see help for emote instead.
EOF
            help_entries.push(Aethyr::Core::Help::HelpEntry.new(command, content: content, syntax_formats: syntax_formats, see_also: see_also, aliases: aliases))

            return help_entries
          end


          def initialize(player)
            super(player, ["cry"], help_entries: CryHandler.create_help_entries)
          end

          def self.object_added(data)
            super(data, self)
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^(cry)( +([^()]*))?( +((.*)))?$/i
              object = $3
              post = $5
              cry({:object => object, :post => post})
            end
          end

          private
          def cry(event)

            room = $manager.get_object(@player.container)
            player = @player

            make_emote event, player, room do

              default do
                to_player "Tears run down your face as you cry pitifully."
                to_other "Tears run down #{player.name}'s face as #{player.pronoun} cries pitifully."
              end
            end
          end

        end
        Aethyr::Extend::HandlerRegistry.register_handler(CryHandler)
      end
    end
  end
end
