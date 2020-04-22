require "aethyr/core/registry"
require "aethyr/core/commands/admin/admin_handler"

module Aethyr
  module Core
    module Commands
      module Alook
        class AlookHandler < Aethyr::Extend::AdminHandler
          def initialize(player)
            super(player, ["alook"])
          end

          def self.object_added(data)
            return unless data[:game_object].is_a? Player
            data[:game_object].subscribe(AlookHandler.new(data[:game_object]))
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^alook$/i
              alook({})
            when /^alook\s+(.*)$/i
              at = $1
              alook({:at => at})
            when /^help (alook)$/i
              action_help_alook({})
            end
          end

          private
          def action_help_alook(event)
            @player.output <<'EOF'
Sorry no help has been written for this command yet
EOF
          end


          def alook(event)

            room = $manager.get_object(@player.container)
            player = @player
            if event[:at].nil?
              object = room
            elsif event[:at].downcase == "here"
              object = $manager.find player.container
            elsif player == event[:at]
              player.output "You can't look at yourself without getting lost forever."
              return
            else
              object = find_object(event[:at], event)
            end

            if object.nil?
              player.output "Cannot find #{event[:at]} to inspect."
              return
            end

            output = "Object: #{object}\n"
            output << "Attributes:\n"

            object.instance_variables.sort.each do |var|
              val = object.instance_variable_get(var)
              if var == :@observer_peers
                val = val.keys.map {|k| k.to_s }
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

            player.output(output)
          end

        end
        Aethyr::Extend::HandlerRegistry.register_handler(AlookHandler)
      end
    end
  end
end
