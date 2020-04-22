require "aethyr/core/registry"
require "aethyr/core/commands/admin/admin_handler"

module Aethyr
  module Core
    module Commands
      module Aset
        class AsetHandler < Aethyr::Extend::AdminHandler
          def initialize(player)
            super(player, ["aset", "aset!"])
          end

          def self.object_added(data)
            return unless data[:game_object].is_a? Player
            data[:game_object].subscribe(AsetHandler.new(data[:game_object]))
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^aset\s+(.+?)\s+(@\w+|smell|feel|texture|taste|sound|listen)\s+(.*)$/i
              object = $1
              attribute = $2
              value = $3
              aset({:object => object, :attribute => attribute, :value => value})
            when /^aset!\s+(.+?)\s+(@\w+|smell|feel|texture|taste|sound|listen)\s+(.*)$/i
              object = $1
              attribute = $2
              value = $3
              force = true
              aset({:object => object, :attribute => attribute, :value => value, :force => force})
            when /^aset!\s+(.+?)\s+(@\w+|smell|feel|texture|taste|sound|listen)\s+(.*)$/i
              object = $1
              attribute = $2
              value = $3
              force = true
              aset({:object => object, :attribute => attribute, :value => value, :force => force})
            when /^help (aset|aset!)$/i
              action_help_aset({})
            end
          end

          private
          def action_help_aset(event)
            @player.output <<'EOF'
Sorry no help has been written for this command yet
EOF
          end


          def aset(event)

            room = $manager.get_object(@player.container)
            player = @player
            if event[:object].downcase == "here"
              event[:object] = player.container
            elsif event[:object] and event[:object].split.first.downcase == "all"
              log event[:object].split
              klass = event[:object].split[1]
              klass.capitalize! unless klass[0,1] == klass[0,1].upcase
              begin
                klass = Module.const_get klass.to_sym
              rescue NameError
                player.output "No such object type."
                return
              end

              objects = $manager.find_all("class", klass)

              objects.each do |obj|
                e = event.dup
                e[:object] = obj.goid

                Admin.aset(e, player, room)
              end

              return
            end

            object = find_object(event[:object], event)

            if object.nil?
              player.output "Cannot find #{event[:object]} to edit."
              return
            end

            attrib = event[:attribute]

            if attrib[0,1] != "@"
              value = event[:value]
              if value.downcase == "!nothing" or value.downcase == "nil"
                value = nil
              end

              if value and value[-1,1] !~ /[!.?"']/
                value << "."
              end

              case attrib.downcase
              when "smell"
                if value.nil?
                  object.info.delete :smell
                  player.output "#{object.name} will no longer smell."
                else
                  object.info.smell = value
                  player.output "#{object.name} will now smell like: #{object.info.smell}"
                end
                return
              when "feel", "texture"
                if value.nil?
                  object.info.delete :texture
                  player.output "#{object.name} will no longer have a particular texture."
                else
                  object.info.texture = value
                  player.output "#{object.name} will now feel like: #{object.info.texture}"
                end
                return
              when "taste"
                if value.nil?
                  object.info.delete :taste
                  player.output "#{object.name} will no longer have a particular taste."
                else
                  object.info.taste = value
                  player.output "#{object.name} will now taste like: #{object.info.taste}"
                end
                return
              when "sound", "listen"
                if value.nil?
                  object.info.delete :sound
                  player.output "#{object.name} will no longer make sounds."
                else
                  object.info.sound = value
                  player.output "#{object.name} will now sound like: #{object.info.sound}"
                end
                return
              else
                player.output "What are you trying to set?"
                return
              end
            end

            if not object.instance_variables.include? attrib and not object.instance_variables.include? attrib.to_sym and not event[:force]
              player.output "#{object}:No such setting/variable/attribute: #{attrib}"
              return
            else
              current_value = object.instance_variable_get(attrib)
              if current_value.is_a? Array
                object.instance_variable_set(attrib, event[:value].split(/s*"(.*?)"\s*|\s+/))
                player.output "Set #{object} attribute #{attrib} to #{event[:value].inspect}"
              else
                value = event[:value] #for ease
                if value.split.length == 1
                  case value.downcase
                  when "true"
                    value = true
                  when "false"
                    value = false
                  when /^:/
                    value = value[1..-1].to_sym
                  when "nil"
                    value = nil
                  when /^[0-9]+$/
                    value = value.to_i unless current_value.is_a? String
                  when "!nothing"
                    value = ""
                  when "!delete"
                    object.instance_eval { remove_instance_variable(attrib) }
                    player.output "Removed attribute #{attrib} from #{object}"
                    return
                  end
                end

                object.instance_variable_set(attrib, value)
                player.output "Set #{object} attribute #{attrib} to #{value}"
              end
            end
          end

        end
        Aethyr::Extend::HandlerRegistry.register_handler(AsetHandler)
      end
    end
  end
end
