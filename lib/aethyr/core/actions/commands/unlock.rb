require "aethyr/core/actions/commands/command_action"

module Aethyr
  module Core
    module Actions
      module Unlock
        class UnlockCommand < Aethyr::Extend::CommandAction
          def initialize(actor, **data)
            super(actor, **data)
          end

          def action

            room = $manager.get_object(self[:agent].container)
            object = self[:agent].search_inv(self[:object]) || room.find(self[:object])

            if object.nil?
              self[:agent].output("Unlock what? #{self[:object]}?")
              return
            elsif not object.can? :unlock or not object.lockable?
              self[:agent].output('That object cannot be unlocked.')
              return
            elsif not object.locked?
              self[:agent].output("#{object.name} is already unlocked.")
              return
            end

            has_key = false
            object.keys.each do |key|
              if self[:agent].inventory.include? key
                has_key = key
                break
              end
            end

            if has_key or self[:agent].admin
              status = object.unlock(has_key, self[:agent].admin)
              if status
                self[:to_player] = "You unlock #{object.name}."
                self[:to_other] = "#{self[:agent].name} unlocks #{object.name}."
                self[:to_blind_other] = "You hear the clunk of a lock."

                room.out_event(event)

                if object.is_a? Door and object.connected?
                  other_side = $manager.find object.connected_to
                  other_side.unlock(has_key)
                  other_room = $manager.find other_side.container
                  o_event = event.dup
                  self[:to_other] = "#{other_side.name} unlocks from the other side."
                  self[:to_blind_other] = "You hear the click of a lock."
                  other_room.out_event(event)
                end

                return
              else
                self[:agent].output("You are unable to unlock #{object.name}.")
                return
              end
            else
              self[:agent].output("You do not have the key to #{object.name}.")
              return
            end
          end
        end
      end
    end
  end
end
