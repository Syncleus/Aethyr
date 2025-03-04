require "aethyr/core/actions/commands/command_action"

module Aethyr
  module Core
    module Actions
      module Ainfo
        class AinfoCommand < Aethyr::Extend::CommandAction
          def initialize(actor, **data)
            super(actor, **data)
          end

          def action
            

            room = $manager.get_object(@player.container)
            player = @player
            if self[:object].downcase == "here"
              self[:object] = player.container
            elsif self[:object].downcase == "me"
              self[:object] = player
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

                Admin.ainfo(e, player, room)
              end

              return
            end

            object = find_object(self[:object], self)

            if object.nil?
              player.output "What object? #{self[:object]}"
              return
            end

            case self[:command]
            when "set"
              value = self[:value] #for ease
              if value.split.length == 1
                if value == "true"
                  value = true
                elsif value == "false"
                  value = false
                elsif value[0,1] == ":"
                  value = value[1..-1].to_sym
                elsif value == "nil"
                  value = nil
                elsif value.match(/^[0-9]+$/)
                  value = value.to_i
                elsif value.downcase == "!nothing"
                  value = ""
                end
              end
              object.info.set(self[:attrib], value)
              player.output "Set #{self[:attrib]} to #{object.info.get(self[:attrib])}"
            when "delete"
              object.info.delete(self[:attrib])
              player.output "Deleted #{self[:attrib]} from #{object}"
            when "show"
              player.output object.info.inspect
            when "clear"
              object.info = Info.new
              player.output "Completely cleared info for #{object}."
            else
              player.output "Huh? What?"
            end
          end

        end
      end
    end
  end
end
