require "aethyr/core/registry"
require "aethyr/core/commands/emotes/emote_handler"

module Aethyr
  module Core
    module Commands
      module Nod
        class NodHandler < Aethyr::Extend::EmoteHandler
          def initialize(player)
            super(player, ["nod"])
          end

          def self.object_added(data)
            super(data, klass: self)
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^(nod)( +([^()]*))?( +((.*)))?$/i
              object = $3
              post = $5
              nod({:object => object, :post => post})
            when /^help (nod)$/i
              action_help_nod({})
            end
          end

          private
          def action_help_nod(event)
            @player.output <<'EOF'
Please see help for emote instead.
EOF
          end


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
