require "aethyr/core/registry"
require "aethyr/core/actions/commands/admin/admin_handler"

module Aethyr
  module Core
    module Commands
      module Alook
        class AlookHandler < Aethyr::Extend::AdminHandler

          def self.create_help_entries
            help_entries = []

            command = "alook"
            see_also = nil
            syntax_formats = ["ALOOK [OBJECT]"]
            aliases = nil
            content =  <<'EOF'
Sorry no help has been written for this command yet
EOF
            help_entries.push(Aethyr::Core::Help::HelpEntry.new(command, content: content, syntax_formats: syntax_formats, see_also: see_also, aliases: aliases))

            return help_entries
          end


          def initialize(player)
            super(player, ["alook"], help_entries: AlookHandler.create_help_entries)
          end

          def self.object_added(data)
            super(data, self)
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^alook$/i
              alook({})
            when /^alook\s+(.*)$/i
              at = $1
              alook({:at => at})
            end
          end

          private
          def alook(event)

            room = $manager.get_object(@player.container)
            player = @player
            if event[:at].nil?
              object = room
            elsif event[:at].downcase == "here"
              object = $manager.find player.container
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

            puts output
            player.output(output)
          end

        end
        Aethyr::Extend::HandlerRegistry.register_handler(AlookHandler)
      end
    end
  end
end
