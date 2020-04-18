require "aethyr/core/registry"
require "aethyr/core/commands/emote_handler"

module Aethyr
  module Core
    module Commands
      module No
        class NoHandler < Aethyr::Extend::EmoteHandler
          def initialize(player)
            super(player, ["no"])
          end

          def self.object_added(data)
            return unless data[:game_object].is_a? Player
            data[:game_object].subscribe(NoHandler.new(data[:game_object]))
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^(no)( +([^()]*))?( +((.*)))?$/i
              object = $3
              post = $5
              no({:object => object, :post => post})
            when /^help (no)$/i
              action_help_no({})
            end
          end

          private
          def action_help_no(event)
            @player.output <<'EOF'
Please see help for emote instead.
EOF
          end


          def no(event)

            room = $manager.get_object(@player.container)
            player = @player
            make_emote event, player, room do
              no_target do
                to_player  "\"No,\" you say, shaking your head."
                to_other "#{player.name} says, \"No\" and shakes #{player.pronoun(:possessive)} head."
              end
              self_target do
                to_player  "You shake your head negatively in your direction. You are kind of strange."
                to_other "#{player.name} shakes #{player.pronoun(:possessive)} head at #{player.pronoun(:reflexive)}."
                to_deaf_other event[:to_other]
              end
              target do
                to_player  "You shake your head, disagreeing with #{event.target.name}."
                to_target "#{player.name} shakes #{player.pronoun(:possessive)} head in your direction, disagreeing."
                to_other "#{player.name} shakes #{player.pronoun(:possessive)} head in disagreement with #{event.target.name}."
                to_deaf_other event[:to_other]
              end
            end

          end

        end
        Aethyr::Extend::HandlerRegistry.register_handler(NoHandler)
      end
    end
  end
end
