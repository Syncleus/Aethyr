require "aethyr/core/actions/commands/command_action"

module Aethyr
  module Core
    module Actions
      module Lock
        class LockCommand < Aethyr::Extend::CommandAction
          def initialize(actor, **data)
            super(actor, **data)
          end

          def action
            
            room = $manager.get_object(@player.container)
            object = @player.search_inv(self[:object]) || room.find(self[:object])

            if object.nil?
              @player.output('Lock what?')
              return
            elsif not object.can? :lock or not object.lockable?
              @player.output('That object cannot be locked.')
              return
            elsif object.locked?
              @player.output("#{object.name} is already locked.")
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
              status = object.lock(has_key, @player.admin)
              if status
                self[:to_player] = "You lock #{object.name}."
                self[:to_other] = "#{@player.name} locks #{object.name}."
                self[:to_blind_other] = "You hear the click of a lock."

                room.out_self(self)

                if object.is_a? Door and object.connected?
                  other_side = $manager.find object.connected_to
                  other_side.lock(has_key)
                  other_room = $manager.find other_side.container
                  o_self = self.dup
                  self[:to_other] = "#{other_side.name} locks from the other side."
                  self[:to_blind_other] = "You hear the click of a lock."
                  other_room.out_self(self)
                end
              else
                @player.output("You are unable to lock that #{object.name}.")
              end
            else
              @player.output("You do not have the key to that #{object.name}.")
            end
          end

        end
      end
    end
  end
end
