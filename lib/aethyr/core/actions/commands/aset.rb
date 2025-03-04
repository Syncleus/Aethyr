require "aethyr/core/actions/commands/command_action"

module Aethyr
  module Core
    module Actions
      module Aset
        class AsetCommand < Aethyr::Extend::CommandAction
          def initialize(actor, **data)
            super(actor, **data)
          end

          def action
            

            room = $manager.get_object(@player.container)
            player = @player
            if self[:object].downcase == "here"
              self[:object] = player.container
            elsif self[:object] and self[:object].split.first.downcase == "all"
              log self[:object].split
              klass = self[:object].split[1]
              klass.capitalize! unless klass[0,1] == klass[0,1].upcase
              begin
                klass = Module.const_get klass.to_sym
              rescue NameError
                player.output "No such object type."
                return
              end

              objects = $manager.find_all("class", klass)

              objects.each do |obj|
                e = self.dup
                e[:object] = obj.goid

                Admin.aset(e, player, room)
              end

              return
            end

            object = find_object(self[:object], self)

            if object.nil?
              player.output "Cannot find #{self[:object]} to edit."
              return
            end

            attrib = self[:attribute]

            if attrib[0,1] != "@"
              value = self[:value]
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

            if not object.instance_variables.include? attrib and not object.instance_variables.include? attrib.to_sym and not self[:force]
              player.output "#{object}:No such setting/variable/attribute: #{attrib}"
              return
            else
              current_value = object.instance_variable_get(attrib)
              if current_value.is_a? Array
                object.instance_variable_set(attrib, self[:value].split(/s*"(.*?)"\s*|\s+/))
                player.output "Set #{object} attribute #{attrib} to #{self[:value].inspect}"
              else
                value = self[:value] #for ease
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
      end
    end
  end
end
