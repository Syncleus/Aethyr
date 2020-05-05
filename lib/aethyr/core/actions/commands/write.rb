require "aethyr/core/actions/command_action"

module Aethyr
  module Core
    module Actions
      module Write
        class WriteCommand < Aethyr::Core::Actions::CommandAction
          def initialize(actor, **data)
            super(actor, **data)
          end

          def action
            event = @data
            object = @player.search_inv(event[:target])

            if object.nil?
              @player.output "What do you wish to write on?"
              return
            end

            if not object.info.writable
              @player.output "You cannot write on #{object.name}."
              return
            end

            @player.output "You begin to write on #{object.name}."

            @player.editor(object.readable_text || [], 100) do |data|
              unless data.nil?
                object.readable_text = data
              end
              @player.output "You finish your writing."
            end
          end
        end
      end
    end
  end
end
