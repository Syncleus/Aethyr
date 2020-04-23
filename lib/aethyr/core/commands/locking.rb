require "aethyr/core/registry"
require "aethyr/core/commands/command_handler"

module Aethyr
  module Core
    module Commands
      module Locking
        class LockingHandler < Aethyr::Extend::CommandHandler
          def initialize(player)
            super(player, ["lock", "unlock"])
          end

          def self.object_added(data)
            super(data, klass: self)
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^lock\s+(.*)$/i
              action_lock({ :object => $1 })
            when /^unlock\s+(.*)$/i
              action_unlock({ :object => $1 })
            when /^help (lock|unlock)$/i
              action_help({})
            end
          end

          private
          def action_help(event)
            @player.output <<'EOF'
Command: Lock
Command: Unlock
Syntax: LOCK [object or direction]
Syntax: UNLOCK [object or direction]

Lock or unlock the given object, if you have a key for it.

Note that you can lock a door while it is open, then close it.

See also: OPEN, CLOSE

EOF
          end

          def action_lock(event)
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
          
          def action_unlock(event)
            room = $manager.get_object(@player.container)
            object = @player.search_inv(event[:object]) || room.find(event[:object])

            if object.nil?
              @player.output("Unlock what? #{event[:object]}?")
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
                event[:to_player] = "You unlock #{object.name}."
                event[:to_other] = "#{@player.name} unlocks #{object.name}."
                event[:to_blind_other] = "You hear the clunk of a lock."

                room.out_event(event)

                if object.is_a? Door and object.connected?
                  other_side = $manager.find object.connected_to
                  other_side.unlock(has_key)
                  other_room = $manager.find other_side.container
                  o_event = event.dup
                  event[:to_other] = "#{other_side.name} unlocks from the other side."
                  event[:to_blind_other] = "You hear the click of a lock."
                  other_room.out_event(event)
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
        
        Aethyr::Extend::HandlerRegistry.register_handler(LockingHandler)
      end
    end
  end
end