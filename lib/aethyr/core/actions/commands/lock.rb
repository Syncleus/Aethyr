require "aethyr/core/actions/command_action"

module Aethyr
  module Core
    module Actions
      module Lock
        class LockCommand < Aethyr::Core::Actions::CommandAction
          def initialize(actor, **data)
            super(actor, **data)
          end

          def action
            event = @data
            room = $manager.get_object(@player.container)
            object = @player.search_inv(event[:object]) || room.find(event[:object])

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
                event[:to_player] = "You lock #{object.name}."
                event[:to_other] = "#{@player.name} locks #{object.name}."
                event[:to_blind_other] = "You hear the click of a lock."

                room.out_event(event)

                if object.is_a? Door and object.connected?
                  other_side = $manager.find object.connected_to
                  other_side.lock(has_key)
                  other_room = $manager.find other_side.container
                  o_event = event.dup
                  event[:to_other] = "#{other_side.name} locks from the other side."
                  event[:to_blind_other] = "You hear the click of a lock."
                  other_room.out_event(event)
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
