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

            if self[:password]
              if $manager.check_password(self[:agent].name, self[:password])
                self[:agent].output "This character #{self[:agent].name} will no longer exist."
                self[:agent].quit
                $manager.delete_player(self[:agent].name)
              else
                self[:agent].output "That password is incorrect. You are allowed to continue existing."
              end
            else
              self[:agent].output "To confirm your deletion, please enter your password:"
              self[:agent].io.echo_off
              self[:agent].expect do |password|
                self[:agent].io.echo_on
                self[:password] = password
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
