require "aethyr/core/registry"
require "aethyr/core/commands/command_handler"

module Aethyr
  module Core
    module Commands
      module Adesc
        class AdescHandler < Aethyr::Extend::CommandHandler
          def initialize(player)
            super(player, ["adesc"])
          end

          def self.object_added(data)
            return unless data[:game_object].is_a? Player
            data[:game_object].subscribe(AdescHandler.new(data[:game_object]))
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^adesc\s+inroom\s+(.*?)\s+(.*)$/i
              object = $1
              inroom = true
              desc = $2
              adesc({:object => object, :inroom => inroom, :desc => desc})
            when /^adesc\s+(.*?)\s+(.*)$/i
              object = $1
              desc = $2
              adesc({:object => object, :desc => desc})
            when /^help (adesc)$/i
              action_help_adesc({})
            end
          end

          private
          def action_help_adesc(event)
            @player.output <<'EOF'
Sorry no help has been written for this command yet
EOF
          end


          def adesc(event)

            room = $manager.get_object(@player.container)
            player = @player
            object = nil
            if event[:object].downcase == "here"
              object = room
            else
              object = find_object(event[:object], event)
            end

            if object.nil?
              player.output "Cannot find #{event[:object]}."
              return
            end

            if event[:inroom]
              if event[:desc].nil? or event[:desc].downcase == "false"
                object.show_in_look = false
                player.output "#{object.name} will not be shown in the room description."
              else
                object.show_in_look= event[:desc]
                player.output "The room will show #{object.show_in_look}"
              end
            else
              object.instance_variable_set(:@short_desc, event[:desc])
              player.output "#{object.name} now looks like:\n#{object.short_desc}"
            end
          end

        end
        Aethyr::Extend::HandlerRegistry.register_handler(AdescHandler)
      end
    end
  end
end
