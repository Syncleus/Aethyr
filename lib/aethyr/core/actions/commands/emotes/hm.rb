require "aethyr/core/actions/commands/emotes/emote_action"

module Aethyr
  module Core
    module Actions
      module Hm
        class HmCommand < Aethyr::Extend::EmoteAction
          def initialize(actor, **data)
            super(actor, **data)
          end

          def action
            

            room = $manager.get_object(@player.container)
            player = @player

            make_emote self, player, room do

              no_target do
                to_other "#{player.name} purses #{player.pronoun(:possessive)} lips thoughtfully and says, \"Hmmm...\""
                to_player "You purse your lips thoughtfully and say, \"Hmmm...\""
              end

              self_target do
                to_other "#{player.name} looks down at #{player.pronoun(:reflexive)} and says, \"Hmmm...\""
                to_player "You look down at yourself and say, \"Hmmm...\""
              end

              target do
                to_other "#{player.name} purses #{player.pronoun(:possessive)} lips as #{player.pronoun} looks thoughtfully at #{self.target.name} and says, \"Hmmm...\""
                to_player "You purse your lips as you look thoughtfully at #{self.target.name} and say, \"Hmmm...\""
                to_target "#{player.name} purses #{player.pronoun(:possessive)} lips as #{player.pronoun} looks thoughtfully at you and says, \"Hmmm...\""
              end
            end

          end

        end
      end
    end
  end
end
