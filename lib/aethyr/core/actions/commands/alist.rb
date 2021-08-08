require "aethyr/core/actions/commands/command_action"

module Aethyr
  module Core
    module Actions
      module Alist
        class AlistCommand < Aethyr::Extend::CommandAction
          def initialize(actor, **data)
            super(actor, **data)
          end

          def action


            room = $manager.get_object(self[:agent].container)
            player = self[:agent]
            objects = nil
            if self[:match].nil?
              objects = $manager.find_all("class", :GameObject)
            else
              objects = $manager.find_all(self[:match], self[:attrib])
            end

            if objects.empty?
              player.output "Nothing like that to list!"
            else
              output = []
              objects.each do |o|
                output << "\t" + o.to_s
              end

              output = output.join("\n")

              player.output(output)
            end
          end

        end
      end
    end
  end
end
