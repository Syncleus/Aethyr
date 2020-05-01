require "aethyr/core/registry"
require "aethyr/core/actions/commands/emotes/emote_handler"

module Aethyr
  module Core
    module Commands
      module Nod
        class NodHandler < Aethyr::Extend::EmoteHandler

          def self.create_help_entries
            help_entries = []

            command = "nod"
            see_also = nil
            syntax_formats = ["NOD"]
            aliases = nil
            content =  <<'EOF'
Please see help for emote instead.
EOF
            help_entries.push(Aethyr::Core::Help::HelpEntry.new(command, content: content, syntax_formats: syntax_formats, see_also: see_also, aliases: aliases))

            return help_entries
          end


          def initialize(player)
            super(player, ["nod"], help_entries: NodHandler.create_help_entries)
          end

          def self.object_added(data)
            super(data, self)
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^(nod)( +([^()]*))?( +((.*)))?$/i
              object = $3
              post = $5
              nod({:object => object, :post => post})
            end
          end

          private
          def nod(event)

            room = $manager.get_object(@player.container)
            player = @player

            make_emote event, player, room do

              no_target do
                to_player "You nod your head."
                to_other "#{player.name} nods #{player.pronoun(:possessive)} head."
                to_deaf_other event[:to_other]
              end

              self_target do
                to_player 'You nod to yourself thoughtfully.'
                to_other "#{player.name} nods to #{player.pronoun(:reflexive)} thoughtfully."
                to_deaf_other event[:to_other]
              end

              target do

                to_player "You nod your head towards #{event.target.name}."
                to_target "#{player.name} nods #{player.pronoun(:possessive)} head towards you."
                to_other "#{player.name} nods #{player.pronoun(:possessive)} head towards #{event.target.name}."
                to_deaf_other event[:to_other]
              end
            end
          end

        end
        Aethyr::Extend::HandlerRegistry.register_handler(NodHandler)
      end
    end
  end
end
