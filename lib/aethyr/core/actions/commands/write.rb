require "aethyr/core/actions/commands/command_action"

module Aethyr
  module Core
    module Actions
      module Write
        class WriteCommand < Aethyr::Extend::CommandAction
          def initialize(actor, **data)
            super(actor, **data)
          end

          def action

            object = self[:agent].search_inv(self[:target])

            if object.nil?
              self[:agent].output "What do you wish to write on?"
              return
            end

            if not object.info.writable
              self[:agent].output "You cannot write on #{object.name}."
              return
            end

            self[:agent].output "You begin to write on #{object.name}."

            self[:agent].editor(object.readable_text || [], 100) do |data|
              unless data.nil?
                object.readable_text = data
              end
              self[:agent].output "You finish your writing."
            end
          end
        end
      end
    end
  end
end
