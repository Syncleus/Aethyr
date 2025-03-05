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
            room = $manager.get_object(@player.container)
            if self[:target].nil?
              if room.info.smell
                self[:to_player] = "You sniff the air. #{room.info.smell}."
              else
                self[:to_player] = "You sniff the air, but detect no unusual aromas."
              end
              self[:to_other] = "#{@player.name} sniffs the air."
              room.out_event self
              return
            end

            object = @player.search_inv(self[:target]) || room.find(self[:target])

            if object == @player or self[:target] == "me"
              self[:target] = @player
              self[:to_player] = "You cautiously sniff your armpits. "
              if rand > 0.6
                self[:to_player] << "Your head snaps back from the revolting stench coming from beneath your arms."
                self[:to_other] = "#{@player.name} sniffs #{@player.pronoun(:possessive)} armpits, then recoils in horror."
              else
                self[:to_player] << "Meh, not too bad."
                self[:to_other] = "#{@player.name} sniffs #{@player.pronoun(:possessive)} armpits, then shrugs, apparently unconcerned with #{@player.pronoun(:possessive)} current smell."
              end
              room.out_event self
              return
            elsif object.nil?
              @player.output "What are you trying to smell?"
              return
            end

            self[:target] = object
            self[:to_player] = "Leaning in slightly, you sniff #{object.name}. "
            if object.info.smell.nil? or object.info.smell == ""
              self[:to_player] << "#{object.pronoun.capitalize} has no particular aroma."
            else
              self[:to_player] << object.info.smell
            end
            self[:to_target] = "#{@player.name} sniffs you curiously."
            self[:to_other] = "#{@player.name} thrusts #{@player.pronoun(:possessive)} nose at #{object.name} and sniffs."
            room.out_event self
          end
        end
      end
    end
  end
end
