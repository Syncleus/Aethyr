require "aethyr/core/actions/command_action"

module Aethyr
  module Core
    module Actions
      module Hm
        class HmCommand < Aethyr::Core::Actions::CommandAction
          def initialize(actor, **data)
            super(actor, **data)
          end

          def action
            event = @data

            room = $manager.get_object(@player.container)
            player = @player

            make_emote event, player, room do

              no_target do
                to_other "#{player.name} purses #{player.pronoun(:possessive)} lips thoughtfully and says, \"Hmmm...\""
                to_player "You purse your lips thoughtfully and say, \"Hmmm...\""
              end

              self_target do
                to_other "#{player.name} looks down at #{player.pronoun(:reflexive)} and says, \"Hmmm...\""
                to_player "You look down at yourself and say, \"Hmmm...\""
              end

              target do
                to_other "#{player.name} purses #{player.pronoun(:possessive)} lips as #{player.pronoun} looks thoughtfully at #{event.target.name} and says, \"Hmmm...\""
                to_player "You purse your lips as you look thoughtfully at #{event.target.name} and say, \"Hmmm...\""
                to_target "#{player.name} purses #{player.pronoun(:possessive)} lips as #{player.pronoun} looks thoughtfully at you and says, \"Hmmm...\""
              end
            end

          end

        end
      end
    end
  end
end
