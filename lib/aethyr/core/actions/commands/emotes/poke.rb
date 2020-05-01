require "aethyr/core/registry"
require "aethyr/core/actions/commands/emotes/emote_handler"

module Aethyr
  module Core
    module Commands
      module Poke
        class PokeHandler < Aethyr::Extend::EmoteHandler

          def self.create_help_entries
            help_entries = []

            command = "poke"
            see_also = nil
            syntax_formats = ["POKE"]
            aliases = nil
            content =  <<'EOF'
Please see help for emote instead.
EOF
            help_entries.push(Aethyr::Core::Help::HelpEntry.new(command, content: content, syntax_formats: syntax_formats, see_also: see_also, aliases: aliases))

            return help_entries
          end


          def initialize(player)
            super(player, ["poke"], help_entries: PokeHandler.create_help_entries)
          end

          def self.object_added(data)
            super(data, self)
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^(poke)( +([^()]*))?( +((.*)))?$/i
              object = $3
              post = $5
              poke({:object => object, :post => post})
            end
          end

          private
          def poke(event)

            room = $manager.get_object(@player.container)
            player = @player

            make_emote event, player, room do

              no_target do
                player.output "Who are you trying to poke?"
              end

              self_target do
                to_player  "You poke yourself in the eye. 'Ow!'"
                to_other "#{player.name} pokes #{player.pronoun(:reflexive)} in the eye."
                to_deaf_other event[:to_other]
              end

              target do
                to_player  "You poke #{event.target.name} playfully."
                to_target "#{player.name} pokes you playfully."
                to_blind_target "Someone pokes you playfully."
                to_deaf_target event[:to_target]
                to_other "#{player.name} pokes #{event.target.name} playfully."
                to_deaf_other event[:to_other]
              end
            end
          end

        end
        Aethyr::Extend::HandlerRegistry.register_handler(PokeHandler)
      end
    end
  end
end
