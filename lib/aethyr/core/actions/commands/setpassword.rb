require "aethyr/core/actions/commands/command_action"

module Aethyr
  module Core
    module Actions
      module Setpassword
        class SetpasswordCommand < Aethyr::Extend::CommandAction
          def initialize(actor, **data)
            super(actor, **data)
          end

          def action
            event = @data

            room = $manager.get_object(@player.container)
            player = @player
            if event[:new_password]
              if event[:new_password] !~ /^\w{6,20}$/
                player.output "Please only use letters and numbers. Password should be between 6 and 20 characters long."
                return
              else
                $manager.set_password(player, event[:new_password])
                player.output "Your password has been changed."
              end
            else
              player.output "Please enter your current password:", true
              player.io.echo_off
              player.expect do |password|
                if $manager.check_password(player.name, password)
                  player.output "Please enter your new password:", true
                  player.io.echo_off
                  player.expect do |password|
                    player.io.echo_on
                    event[:new_password] = password
                    Settings.setpassword(event, player, room)
                  end
                else
                  player.output "Sorry, that password is invalid."
                  player.io.echo_on
                end

              end
            end
          end

        end
      end
    end
  end
end
