require "aethyr/core/registry"
require "aethyr/core/commands/emotes/emote_handler"

module Aethyr
  module Core
    module Commands
      module Eh
        class EhHandler < Aethyr::Extend::EmoteHandler
          def initialize(player)
            super(player, ["eh", "eh?"])
          end

          def self.object_added(data)
            super(data, self)
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^(eh\?)( +([^()]*))?( +((.*)))?$/i
              object = $3
              post = $5
              eh?({:object => object, :post => post})
            when /^(eh)( +([^()]*))?( +((.*)))?$/i
              object = $3
              post = $5
              eh({:object => object, :post => post})
            when /^help (eh|eh\?)$/i
              action_help_eh({})
            end
          end

          private
          def action_help_eh(event)
            @player.output <<'EOF'
Please see help for emote instead.
EOF
          end


          def eh(event)

            room = $manager.get_object(@player.container)
            player = @player
            make_emote event, player, room do
              target do
                to_player "After giving #{event.target.name} a cursory glance, you emit an unimpressed, 'Eh.'"
                to_other "#{player.name} gives #{event.target.name} a cursory glance and then emits an unimpressed, 'Eh.'"
                to_target "#{player.name} gives you a cursory glance and then emits an unimpressed, 'Eh.'"
              end

              no_target do
                to_player "After a brief consideration, you give an unimpressed, 'Eh.'"
                to_other "#{player.name} appears to consider for a moment before giving an unimpressed, 'Eh.'"
              end
            end
          end

          def eh?(event)

            room = $manager.get_object(@player.container)
            player = @player

            make_emote event, player, room do
              no_target do
                to_player "Thoughtfully, you murmur, \"Eh?\""
                to_other "#{player.name} murmurs, \"Eh?\" with a thoughtful appearance."
              end

              target do
                to_player "Looking perplexed, you ask #{target.name}, \"Eh?\""
                to_other "\"Eh?\" #{player.name} asks #{target.name}, looking perplexed."
                to_target "\"Eh?\" #{player.name} asks you, with a perplexed expression."
              end
            end
          end

        end
        Aethyr::Extend::HandlerRegistry.register_handler(EhHandler)
      end
    end
  end
end
