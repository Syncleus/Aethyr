require "aethyr/core/actions/commands/command_action"

module Aethyr
  module Core
    module Actions
      module Deleteme
        class DeletemeCommand < Aethyr::Extend::CommandAction
          def initialize(actor, **data)
            super(actor, **data)
          end

          def action
            event = @data
            if event[:password]
              if $manager.check_password(@player.name, event[:password])
                @player.output "This character #{@player.name} will no longer exist."
                @player.quit
                $manager.delete_player(@player.name)
              else
                @player.output "That password is incorrect. You are allowed to continue existing."
              end
            else
              @player.output "To confirm your deletion, please enter your password:"
              @player.io.echo_off
              @player.expect do |password|
                @player.io.echo_on
                event[:password] = password
                Generic.deleteme(event)
              end
            end
          end
          #Write something.
        end
      end
    end
  end
end
