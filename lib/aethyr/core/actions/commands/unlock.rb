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
            
            room = $manager.get_object(@player.container)
            object = @player.search_inv(self[:object]) || room.find(self[:object])

            if object.nil?
              @player.output("Unlock what? #{self[:object]}?")
              return
            elsif not object.can? :unlock or not object.lockable?
              @player.output('That object cannot be unlocked.')
              return
            elsif not object.locked?
              @player.output("#{object.name} is already unlocked.")
              return
            end

            has_key = false
            object.keys.each do |key|
              if @player.inventory.include? key
                has_key = key
                break
              end
            end

            if has_key or @player.admin
              status = object.unlock(has_key, @player.admin)
              if status
                self[:to_player] = "You unlock #{object.name}."
                self[:to_other] = "#{@player.name} unlocks #{object.name}."
                self[:to_blind_other] = "You hear the clunk of a lock."

                room.out_self(self)

                if object.is_a? Door and object.connected?
                  other_side = $manager.find object.connected_to
                  other_side.unlock(has_key)
                  other_room = $manager.find other_side.container
                  o_self = self.dup
                  self[:to_other] = "#{other_side.name} unlocks from the other side."
                  self[:to_blind_other] = "You hear the click of a lock."
                  other_room.out_self(self)
                end

                return
              else
                @player.output("You are unable to unlock #{object.name}.")
                return
              end
            else
              @player.output("You do not have the key to #{object.name}.")
              return
            end
          end
        end
      end
    end
  end
end
