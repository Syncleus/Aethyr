require "aethyr/core/registry"
require "aethyr/core/commands/emote_handler"

module Aethyr
  module Core
    module Commands
      module Yes
        class YesHandler < Aethyr::Extend::EmoteHandler
          def initialize(player)
            super(player, ["yes"])
          end

          def self.object_added(data)
            return unless data[:game_object].is_a? Player
            data[:game_object].subscribe(YesHandler.new(data[:game_object]))
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^(yes)( +([^()]*))?( +((.*)))?$/i
              object = $3
              post = $5
              yes({:object => object, :post => post})
            when /^help (yes)$/i
              action_help_yes({})
            end
          end

          private
          def action_help_yes(event)
            @player.output <<'EOF'
Please see help for emote instead.
EOF
          end


          def yes(event)

            room = $manager.get_object(@player.container)
            player = @player
            make_emote event, player, room do

              no_target do
                to_player  "\"Yes,\" you say, nodding."
                to_other "#{player.name} says, \"Yes\" and nods."
              end

              self_target do
                to_player  "You nod in agreement with yourself."
                to_other "#{player.name} nods at #{player.pronoun(:reflexive)} strangely."
                to_deaf_other event[:to_other]
              end

              target do
                to_player  "You nod in agreement with #{event.target.name}."
                to_target "#{player.name} nods in your direction, agreeing."
                to_other "#{player.name} nods in agreement with #{event.target.name}."
                to_deaf_other event[:to_other]
              end
            end

          end

        end
        Aethyr::Extend::HandlerRegistry.register_handler(YesHandler)
      end
    end
  end
end
