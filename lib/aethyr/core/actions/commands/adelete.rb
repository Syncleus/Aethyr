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
            

            room = $manager.get_object(@player.container)
            player = @player
            if self[:object] and self[:object].split.first.downcase == "all"
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

                Admin.adelete(e, player, room)
              end

              return
            end

            object = find_object(self[:object], self)

            if object.nil?
              player.output "Cannot find #{self[:object]} to delete."
              return
            elsif object.is_a? Aethyr::Core::Objects::Player
              player.output "Use the DELETEPLAYER command to delete other players."
              return
            end

            object_container = object.container

            $manager.delete_object(object)

            if room and room.goid == object.container
              self[:to_player] = "You casually wave your hand and #{object.name} disappears."
              self[:to_other] = "With a casual wave of #{player.pronoun(:possessive)} hand, #{player.name} makes #{object.name} disappear."
              room.out_event self
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
