require "aethyr/core/actions/command_action"

module Aethyr
  module Core
    module Actions
      module Awatch
        class AwatchCommand < Aethyr::Core::Actions::CommandAction
          def initialize(actor, **data)
            super(actor, **data)
          end

          def action
            event = @data

            room = $manager.get_object(@player.container)
            player = @player
            object = find_object(event[:target], event)
            if object.nil?
              player.output "What mobile do you want to watch?"
              return
            elsif not object.is_a? Mobile
              player.output "You can only use this to watch mobiles."
              return
            end

            case event[:command]
            when "start"
              if object.info.redirect_output_to == player.goid
                player.output "You are already watching #{object.name}."
              else
                object.info.redirect_output_to = player.goid
                player.output "Watching #{object.name}."
                object.output "#{player.name} is watching you."
              end
            when "stop"
              if object.info.redirect_output_to != player.goid
                player.output "You are not watching #{object.name}."
              else
                object.info.redirect_output_to = nil
                player.output "No longer watching #{object.name}."
              end
            else
              if object.info.redirect_output_to != player.goid
                object.info.redirect_output_to = player.goid
                player.output "Watching #{object.name}."
                object.output "#{player.name} is watching you."
              else
                object.info.redirect_output_to = nil
                player.output "No longer watching #{object.name}."
              end
            end
          end

        end
      end
    end
  end
end
