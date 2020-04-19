require "aethyr/core/registry"
require "aethyr/core/commands/command_handler"

module Aethyr
  module Core
    module Commands
      module Ainfo
        class AinfoHandler < Aethyr::Extend::CommandHandler
          def initialize(player)
            super(player, ["ainfo"])
          end

          def self.object_added(data)
            return unless data[:game_object].is_a? Player
            data[:game_object].subscribe(AinfoHandler.new(data[:game_object]))
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^ainfo\s+set\s+(.+)\s+@((\w|\.|\_)+)\s+(.*?)$/i
              command = "set"
              object = $1
              attrib = $2
              value = $4
              ainfo({:command => command, :object => object, :attrib => attrib, :value => value})
            when /^ainfo\s+(show|clear)\s+(.*)$/i
              object = $2
              command = $1
              ainfo({:object => object, :command => command})
            when /^ainfo\s+(del|delete)\s+(.+)\s+@((\w|\.|\_)+)$/i
              command = "delete"
              object = $2
              attrib = $3
              ainfo({:command => command, :object => object, :attrib => attrib})
            when /^help (ainfo)$/i
              action_help_ainfo({})
            end
          end

          private
          def action_help_ainfo(event)
            @player.output <<'EOF'
Sorry no help has been written for this command yet
EOF
          end


          def ainfo(event)

            room = $manager.get_object(@player.container)
            player = @player
            if event[:object].downcase == "here"
              event[:object] = player.container
            elsif event[:object].downcase == "me"
              event[:object] = player
            elsif event[:object] and event[:object].split.first.downcase == "all"
              log event[:object].split
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

                Admin.ainfo(e, player, room)
              end

              return
            end

            object = find_object(event[:object], event)

            if object.nil?
              player.output "What object? #{event[:object]}"
              return
            end

            case event[:command]
            when "set"
              value = event[:value] #for ease
              if value.split.length == 1
                if value == "true"
                  value = true
                elsif value == "false"
                  value = false
                elsif value[0,1] == ":"
                  value = value[1..-1].to_sym
                elsif value == "nil"
                  value = nil
                elsif value.match(/^[0-9]+$/)
                  value = value.to_i
                elsif value.downcase == "!nothing"
                  value = ""
                end
              end
              object.info.set(event[:attrib], value)
              player.output "Set #{event[:attrib]} to #{object.info.get(event[:attrib])}"
            when "delete"
              object.info.delete(event[:attrib])
              player.output "Deleted #{event[:attrib]} from #{object}"
            when "show"
              player.output object.info.inspect
            when "clear"
              object.info = Info.new
              player.output "Completely cleared info for #{object}."
            else
              player.output "Huh? What?"
            end
          end

        end
        Aethyr::Extend::HandlerRegistry.register_handler(AinfoHandler)
      end
    end
  end
end