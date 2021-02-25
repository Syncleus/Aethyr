require "aethyr/core/actions/commands/command_action"

module Aethyr
  module Core
    module Actions
      module Smell
        class SmellCommand < Aethyr::Extend::CommandAction
          def initialize(actor, **data)
            super(actor, **data)
          end

          def action
            event = @data.dup
            room = $manager.get_object(@player.container)
            if event[:target].nil?
              if room.info.smell
                event[:to_player] = "You sniff the air. #{room.info.smell}."
              else
                event[:to_player] = "You sniff the air, but detect no unusual aromas."
              end
              event[:to_other] = "#{@player.name} sniffs the air."
              room.out_event event
              return
            end

            object = @player.search_inv(event[:target]) || room.find(event[:target])

            if object == @player or event[:target] == "me"
              event[:target] = @player
              event[:to_player] = "You cautiously sniff your armpits. "
              if rand > 0.6
                event[:to_player] << "Your head snaps back from the revolting stench coming from beneath your arms."
                event[:to_other] = "#{@player.name} sniffs #{@player.pronoun(:possessive)} armpits, then recoils in horror."
              else
                event[:to_player] << "Meh, not too bad."
                event[:to_other] = "#{@player.name} sniffs #{@player.pronoun(:possessive)} armpits, then shrugs, apparently unconcerned with #{@player.pronoun(:possessive)} current smell."
              end
              room.out_event event
              return
            elsif object.nil?
              @player.output "What are you trying to smell?"
              return
            end

            event[:target] = object
            event[:to_player] = "Leaning in slightly, you sniff #{object.name}. "
            if object.info.smell.nil? or object.info.smell == ""
              event[:to_player] << "#{object.pronoun.capitalize} has no particular aroma."
            else
              event[:to_player] << object.info.smell
            end
            event[:to_target] = "#{@player.name} sniffs you curiously."
            event[:to_other] = "#{@player.name} thrusts #{@player.pronoun(:possessive)} nose at #{object.name} and sniffs."
            room.out_event event
          end
        end
      end
    end
  end
end
