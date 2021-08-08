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
            unless target and target.is_a? Player
              self[:agent].output "That person is not available."
              return
            end

            if target == self[:agent]
              self[:agent].output "Talking to yourself?"
              return
            end

            phrase = self[:message]

            last_char = phrase[-1..-1]

            unless ["!", "?", "."].include? last_char
              phrase << "."
            end

            phrase[0,1] = phrase[0,1].upcase
            phrase = phrase.strip.gsub(/\s{2,}/, ' ')

            self[:agent].output "You tell #{target.name}, <tell>\"#{phrase}\"</tell>"
            target.output "#{self[:agent].name} tells you, <tell>\"#{phrase}\"</tell>"
            target.reply_to = self[:agent].name
          end

          #Reply to a tell.
        end
      end
    end
  end
end
