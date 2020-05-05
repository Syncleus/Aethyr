require "aethyr/core/actions/command_action"

module Aethyr
  module Core
    module Actions
      module Adesc
        class AdescCommand < Aethyr::Core::Actions::CommandAction
          def initialize(actor, **data)
            super(actor, **data)
          end

          def action
            event = @data

            room = $manager.get_object(@player.container)
            player = @player
            object = nil
            if event[:object].downcase == "here"
              object = room
            else
              object = find_object(event[:object], event)
            end

            if object.nil?
              player.output "Cannot find #{event[:object]}."
              return
            end

            if event[:inroom]
              if event[:desc].nil? or event[:desc].downcase == "false"
                object.show_in_look = false
                player.output "#{object.name} will not be shown in the room description."
              else
                object.show_in_look= event[:desc]
                player.output "The room will show #{object.show_in_look}"
              end
            else
              object.instance_variable_set(:@short_desc, event[:desc])
              player.output "#{object.name} now looks like:\n#{object.short_desc}"
            end
          end

        end
      end
    end
  end
end
