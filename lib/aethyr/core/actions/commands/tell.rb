require "aethyr/core/actions/commands/command_action"

module Aethyr
  module Core
    module Actions
      module Tell
        class TellCommand < Aethyr::Extend::CommandAction
          def initialize(actor, **data)
            super(actor, **data)
          end

          def action
            
            target = $manager.find self[:target]
            unless target and target.is_a? Aethyr::Core::Objects::Player
              @player.output "You can't send a tell to #{self[:target]}."
              return
            end

            if target == @player
              @player.output "Talking to yourself?"
              return
            end

            phrase = self[:message]

            last_char = phrase[-1..-1]

            unless ["!", "?", "."].include? last_char
              phrase << "."
            end

            phrase[0,1] = phrase[0,1].upcase
            phrase = phrase.strip.gsub(/\s{2,}/, ' ')

            @player.output "You tell #{target.name}, <tell>\"#{phrase}\"</tell>"
            target.output "#{@player.name} tells you, <tell>\"#{phrase}\"</tell>"
            target.reply_to = @player.name
          end

          #Reply to a tell.
        end
      end
    end
  end
end
