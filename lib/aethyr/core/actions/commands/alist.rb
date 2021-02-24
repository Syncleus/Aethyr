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
            event = @data

            room = $manager.get_object(@player.container)
            player = @player
            objects = nil
            if event[:match].nil?
              objects = $manager.find_all("class", :GameObject)
            else
              objects = $manager.find_all(event[:match], event[:attrib])
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
