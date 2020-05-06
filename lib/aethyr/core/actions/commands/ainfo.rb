require "aethyr/core/actions/command_action"

module Aethyr
  module Core
    module Actions
      module Ainfo
        class AinfoCommand < Aethyr::Extend::CommandAction
          def initialize(actor, **data)
            super(actor, **data)
          end

          def action
            event = @data

            room = $manager.get_object(@player.container)
            player = @player
            if event[:object].downcase == "here"
              event[:object] = player.container
            elsif event[:object].downcase == "me"
              event[:object] = player
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

                Admin.ainfo(e, player, room)
              end

              return
            end

            object = find_object(event[:object], event)

            if object.nil?
              player.output "What object? #{event[:object]}"
              return
            end

            case event[:command]
            when "set"
              value = event[:value] #for ease
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
              object.info.set(event[:attrib], value)
              player.output "Set #{event[:attrib]} to #{object.info.get(event[:attrib])}"
            when "delete"
              object.info.delete(event[:attrib])
              player.output "Deleted #{event[:attrib]} from #{object}"
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
