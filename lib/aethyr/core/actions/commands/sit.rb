require "aethyr/core/actions/commands/command_action"

module Aethyr
  module Core
    module Actions
      module Sit
        class SitCommand < Aethyr::Extend::CommandAction
          def initialize(actor, **data)
            super(actor, **data)
          end

          def action
            

            room = $manager.get_object(@player.container)
            player = @player
            if not player.balance
              player.output "You cannot sit properly while unbalanced."
              return
            elsif self[:object].nil?
              if player.sitting?
                player.output('You are already sitting down.')
              elsif player.prone? and player.sit
                self[:to_player] = 'You stand up then sit on the ground.'
                self[:to_other] = "#{player.name} stands up then sits down on the ground."
                self[:to_deaf_other] = self[:to_other]
                room.output(self)
              elsif player.sit
                self[:to_player] = 'You sit down on the ground.'
                self[:to_other] = "#{player.name} sits down on the ground."
                self[:to_deaf_other] = self[:to_other]
                room.out_event(self)
              else
                player.output('You are unable to sit down.')
              end
            else
              object = $manager.find(self[:object], player.room)

              if object.nil?
                player.output('What do you want to sit on?')
              elsif not object.can? :sittable?
                player.output("You cannot sit on #{object.name}.")
              elsif object.occupied_by? player
                player.output("You are already sitting there!")
              elsif not object.has_room?
                player.output("The #{object.generic} #{object.plural? ? "are" : "is"} already occupied.")
              elsif player.sit(object)
                object.sat_on_by(player)
                self[:to_player] = "You sit down on #{object.name}."
                self[:to_other] = "#{player.name} sits down on #{object.name}."
                self[:to_deaf_other] = self[:to_other]
                room.out_event(self)
              else
                player.output('You are unable to sit down.')
              end
            end
          end

        end
      end
    end
  end
end
