require "aethyr/core/actions/commands/command_action"

module Aethyr
  module Core
    module Actions
      module Areaction
        class AreactionCommand < Aethyr::Extend::CommandAction
          def initialize(actor, **data)
            super(actor, **data)
          end

          def action


            room = $manager.get_object(self[:agent].container)
            player = self[:agent]

            if self[:command] == "reload" and self[:object] and self[:object].downcase == "all"
              objects = $manager.find_all("class", Reacts)

              objects.each do |o|
                o.reload_reactions
              end

              player.output "Updated reactions for #{objects.length} objects."
            elsif self[:object] and self[:object].split.first.downcase == "all"
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
                e = event.dup
                e[:object] = obj.goid

                player.output "(Doing #{obj})"
                Admin.areaction(e, player, room)
              end
            else
              if self[:object] == "here"
                object = room
              else
                object = find_object(self[:object], event)
              end

              if object.nil?
                player.output "Cannot find:#{self[:object]}"
                return
              elsif not object.is_a? Reacts and (self[:command] == "load" or self[:command] == "reload")
                player.output "Object cannot react, adding react ability."
                object.extend(Reacts)
              end

              case self[:command]
              when "add"
                if object.actions.add? self[:action_name]
                  player.output "Added #{self[:action_name]}"
                else
                  player.output "Already had a reaction by that name."
                end
              when "delete"
                if object.actions.delete? self[:action_name]
                  player.output "Removed #{self[:action_name]}"
                else
                  player.output "That verb was not associated with this object."
                end
              when "load"
                unless File.exist? "objects/reactions/#{self[:file]}.rx"
                  player.output "No such reaction file - #{self[:file]}"
                  return
                end

                object.load_reactions self[:file]
                player.output "Probably loaded reactions."
              when "reload"
                object.reload_reactions if object.can? :reload_reactions
                player.output "Probably reloaded reactions."
              when "clear"
                object.unload_reactions if object.can? :unload_reactions
                player.output "Probably cleared out reactions."
              when "show"
                if object.actions and not object.actions.empty?
                  player.output "Custom actions: #{object.actions.to_a.sort.join(' ')}", true
                end

                if object.can? :show_reactions
                  player.output object.show_reactions
                else
                  player.output "Object does not react."
                end
              else
                player.output("Options:", true)
                player.output("areaction load <object> <file>", true)
                player.output("areaction reload <object> <file>", true)
                player.output("areaction [add|delete] <object> <action>", true)
                player.output("areaction [clear|show] <object>")
              end
            end
          end

        end
      end
    end
  end
end
