require "aethyr/core/registry"
require "aethyr/core/commands/command_handler"

module Aethyr
  module Core
    module Commands
      module Awatch
        class AwatchHandler < Aethyr::Extend::CommandHandler
          def initialize(player)
            super(player, ["awatch"])
          end

          def self.object_added(data)
            return unless data[:game_object].is_a? Player
            data[:game_object].subscribe(AwatchHandler.new(data[:game_object]))
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^awatch\s+((start|stop)\s+)?(.*)$/i
              target = $3.downcase if $3
              command = $2.downcase if $2
              awatch({:target => target, :command => command})
            when /^help (awatch)$/i
              action_help_awatch({})
            end
          end

          private
          def action_help_awatch(event)
            @player.output <<'EOF'
Sorry no help has been written for this command yet
EOF
          end


          def awatch(event)

            room = $manager.get_object(@player.container)
            player = @player
            object = find_object(event[:target], event)
            if object.nil?
              player.output "What mobile do you want to watch?"
              return
            elsif not object.is_a? Mobile
              player.output "You can only use this to watch mobiles."
              return
            end

            case event[:command]
            when "start"
              if object.info.redirect_output_to == player.goid
                player.output "You are already watching #{object.name}."
              else
                object.info.redirect_output_to = player.goid
                player.output "Watching #{object.name}."
                object.output "#{player.name} is watching you."
              end
            when "stop"
              if object.info.redirect_output_to != player.goid
                player.output "You are not watching #{object.name}."
              else
                object.info.redirect_output_to = nil
                player.output "No longer watching #{object.name}."
              end
            else
              if object.info.redirect_output_to != player.goid
                object.info.redirect_output_to = player.goid
                player.output "Watching #{object.name}."
                object.output "#{player.name} is watching you."
              else
                object.info.redirect_output_to = nil
                player.output "No longer watching #{object.name}."
              end
            end
          end

        end
        Aethyr::Extend::HandlerRegistry.register_handler(AwatchHandler)
      end
    end
  end
end
