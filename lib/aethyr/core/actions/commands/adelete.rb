require "aethyr/core/actions/commands/command_action"

module Aethyr
  module Core
    module Actions
      module Adelete
        class AdeleteCommand < Aethyr::Extend::CommandAction
          def initialize(actor, **data)
            super(actor, **data)
          end

          def action
            event = @data

            room = $manager.get_object(@player.container)
            player = @player
            if event[:object] and event[:object].split.first.downcase == "all"
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

                Admin.adelete(e, player, room)
              end

              return
            end

            object = find_object(event[:object], event)

            if object.nil?
              player.output "Cannot find #{event[:object]} to delete."
              return
            elsif object.is_a? Player
              player.output "Use DELETEPLAYER to delete players."
              return
            end

            object_container = object.container

            $manager.delete_object(object)

            if room and room.goid == object.container
              event[:to_player] = "You casually wave your hand and #{object.name} disappears."
              event[:to_other] = "With a casual wave of #{player.pronoun(:possessive)} hand, #{player.name} makes #{object.name} disappear."
              room.out_event event
            else
              player.output "You casually wave your hand and #{object.name} disappears."
            end

            player.output "#{object} deleted."
          end

        end
      end
    end
  end
end
