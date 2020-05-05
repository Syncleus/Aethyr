require "aethyr/core/actions/command_action"

module Aethyr
  module Core
    module Actions
      module Portal
        class PortalCommand < Aethyr::Core::Actions::CommandAction
          def initialize(actor, **data)
            super(actor, **data)
          end

          def action
            event = @data

            room = $manager.get_object(@player.container)
            player = @player
            object = find_object(event[:object], event)
            if object.nil?
              player.output "Cannot find #{event[:object]}"
              return
            elsif not object.is_a? Portal
              player.output "That is not a portal."
              return
            end

            value = event[:value]

            case event[:setting]
            when "action"
              value.downcase!
              if value == "enter"
                object.info.delete :portal_action
                player.output "Set portal action to enter"
              elsif ["jump", "climb", "crawl"].include? value
                object.info.portal_action = value.downcase.to_sym
                player.output "Set portal action to #{value}"
              else
                player.output "#{value} is not a valid portal action."
              end
            when "exit"
              if value.downcase == "!nothing" or value.downcase == "nil"
                object.info.delete :exit_message
              else
                if value[-1,1] !~ /[!.?"']/
                  value << "."
                end
                object.info.exit_message = value
              end
              player.output "#{object.name} exit message set to: #{object.info.exit_message}"
            when "entrance"
              if value.downcase == "!nothing" or value.downcase == "nil"
                object.info.delete :entrance_message
              else
                if value[-1,1] !~ /[!.?"']/
                  value << "."
                end
                object.info.entrance_message = value
              end
              player.output "#{object.name} entrance message set to: #{object.info.entrance_message}"
            when "portal"
              if value.downcase == "!nothing" or value.downcase == "nil"
                object.info.delete :portal_message
              else
                if value[-1,1] !~ /[!.?"']/
                  value << "."
                end
                object.info.portal_message = value
              end
              player.output "#{object.name} portal message set to: #{object.info.portal_message}"
            else
              player.output "Valid options: action, exit, entrance, or portal."
            end
          end

        end
      end
    end
  end
end
