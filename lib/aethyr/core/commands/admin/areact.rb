require "aethyr/core/registry"
require "aethyr/core/commands/admin/admin_handler"

module Aethyr
  module Core
    module Commands
      module Areact
        class AreactHandler < Aethyr::Extend::AdminHandler
          def initialize(player)
            super(player, ["areact"])
          end

          def self.object_added(data)
            super(data, self)
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^areact\s+load\s+(.*?)\s+(\w+)$/i
              object = $1
              command = "load"
              file = $2
              areaction({:object => object, :command => command, :file => file})
            when /^areact\s+(reload|clear|show)\s+(.*?)$/i
              object = $2
              command = $1
              areaction({:object => object, :command => command})
            when /^areact\s+(add|delete)\s+(.*?)\s+(\w+)$/i
              object = $2
              command = $1
              action_name = $3
              areaction({:object => object, :command => command, :action_name => action_name})
            when /^help (areact)$/i
              action_help_areact({})
            end
          end

          private
          def action_help_areact(event)
            @player.output <<'EOF'
Sorry no help has been written for this command yet
EOF
          end


          def areaction(event)

            room = $manager.get_object(@player.container)
            player = @player

            if event[:command] == "reload" and event[:object] and event[:object].downcase == "all"
              objects = $manager.find_all("class", Reacts)

              objects.each do |o|
                o.reload_reactions
              end

              player.output "Updated reactions for #{objects.length} objects."
            elsif event[:object] and event[:object].split.first.downcase == "all"
              klass = event[:object].split[1]
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
              if event[:object] == "here"
                object = room
              else
                object = find_object(event[:object], event)
              end

              if object.nil?
                player.output "Cannot find:#{event[:object]}"
                return
              elsif not object.is_a? Reacts and (event[:command] == "load" or event[:command] == "reload")
                player.output "Object cannot react, adding react ability."
                object.extend(Reacts)
              end

              case event[:command]
              when "add"
                if object.actions.add? event[:action_name]
                  player.output "Added #{event[:action_name]}"
                else
                  player.output "Already had a reaction by that name."
                end
              when "delete"
                if object.actions.delete? event[:action_name]
                  player.output "Removed #{event[:action_name]}"
                else
                  player.output "That verb was not associated with this object."
                end
              when "load"
                unless File.exist? "objects/reactions/#{event[:file]}.rx"
                  player.output "No such reaction file - #{event[:file]}"
                  return
                end

                object.load_reactions event[:file]
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
        Aethyr::Extend::HandlerRegistry.register_handler(AreactHandler)
      end
    end
  end
end
