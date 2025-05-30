require "aethyr/core/actions/commands/command_action"
require "aethyr/core/util/log"

module Aethyr
  module Core
    module Actions
      module Alook
        class AlookCommand < Aethyr::Extend::CommandAction
          def initialize(actor, **data)
            super(actor, **data)
          end

          def action
            

            room = $manager.get_object(@player.container)
            player = @player
            if self[:at].nil?
              object = room
            elsif self[:at].downcase == "here"
              object = $manager.find player.container
            else
              object = find_object(self[:at], self)
            end

            if object.nil?
              player.output "Cannot find #{self[:at]} to inspect."
              return
            end

            output = "Object: #{object}\n"
            output << "Attributes:\n"

            object.instance_variables.sort.each do |var|
              val = object.instance_variable_get(var)
              if var == :@observer_peers
                val = val.keys.map {|k| k.to_s }
              elsif var == :@local_registrations
                val = val.map { |e| e.instance_variable_get(:@listener).to_s.tr('#<>', '') }
              end
              output << "\t#{var} = #{val}\n"
            end

            output << "\r\nInventory:\r\n"

            if object.respond_to? :inventory
              object.inventory.each do |o|
                output << "\t#{o.name} # #{o.goid} #{object.inventory.position(o) == nil ? "" : object.inventory.position(o).map(&:to_s).join('x')}\n"
              end
            else
              output << "\tNo Inventory"
            end

            if object.respond_to? :equipment
              output << "\r\nEquipment:\r\n"
              object.equipment.inventory.each do |o|
                output << "\t#{o.name} # #{o.goid}\n"
              end
              output << "\t#{object.equipment.equipment.inspect}\n"
            end

            log output, Logger::Ultimate
            player.output(output)
          end

        end
      end
    end
  end
end
