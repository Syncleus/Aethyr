require "aethyr/core/actions/commands/command_action"

module Aethyr
  module Core
    module Actions
      module Adesc
        class AdescCommand < Aethyr::Extend::CommandAction
          def initialize(actor, **data)
            super(actor, **data)
          end

          def action


            room = $manager.get_object(self[:agent].container)
            player = self[:agent]
            object = nil
            if self[:object].downcase == "here"
              object = room
            else
              object = find_object(self[:object], event)
            end

            if object.nil?
              player.output "Cannot find #{self[:object]}."
              return
            end

            if self[:inroom]
              if self[:desc].nil? or self[:desc].downcase == "false"
                object.show_in_look = false
                player.output "#{object.name} will not be shown in the room description."
              else
                object.show_in_look= self[:desc]
                player.output "The room will show #{object.show_in_look}"
              end
            else
              object.instance_variable_set(:@short_desc, self[:desc])
              player.output "#{object.name} now looks like:\n#{object.short_desc}"
            end
          end

        end
      end
    end
  end
end
