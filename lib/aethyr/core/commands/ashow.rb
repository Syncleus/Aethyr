require "aethyr/core/registry"
require "aethyr/core/commands/command_handler"

module Aethyr
  module Core
    module Commands
      module Ashow
        class AshowHandler < Aethyr::Extend::CommandHandler
          def initialize(player)
            super(player, ["ashow"])
          end

          def self.object_added(data)
            return unless data[:game_object].is_a? Player
            data[:game_object].subscribe(AshowHandler.new(data[:game_object]))
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^ashow\s+(.*)$/i
              object = $1
              hide = false
              ahide({:object => object, :hide => hide})
            when /^help (ashow)$/i
              action_help_ashow({})
            end
          end

          private
          def action_help_ashow(event)
            @player.output <<'EOF'
Sorry no help has been written for this command yet
EOF
          end


          def ahide(event)

            room = $manager.get_object(@player.container)
            player = @player
            object = find_object(event[:object], event)

            if object.nil?
              player.output "Cannot find #{event[:object]}."
              return
            end

            if event[:hide]
              object.show_in_look = ""
              player.output "#{object.name} is now hidden."
            elsif object.show_in_look == ""
              object.show_in_look = false
              player.output "#{object.name} is no longer hidden."
            else
              player.output "This object is not hidden."
            end
          end

        end
        Aethyr::Extend::HandlerRegistry.register_handler(AshowHandler)
      end
    end
  end
end
