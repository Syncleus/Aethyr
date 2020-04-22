require "aethyr/core/registry"
require "aethyr/core/commands/admin/admin_handler"

module Aethyr
  module Core
    module Commands
      module Alog
        class AlogHandler < Aethyr::Extend::AdminHandler
          def initialize(player)
            super(player, ["alog"])
          end

          def self.object_added(data)
            return unless data[:game_object].is_a? Player
            data[:game_object].subscribe(AlogHandler.new(data[:game_object]))
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^alog\s+(\w+)(\s+(\d+))?$/i
              command = $1
              value = $3.downcase if $3
              alog({:command => command, :value => value})
            when /^help (alog)$/i
              action_help_alog({})
            end
          end

          private
          def action_help_alog(event)
            @player.output <<'EOF'
Sorry no help has been written for this command yet
EOF
          end


          def alog(event)

            room = $manager.get_object(@player.container)
            player = @player
            if event[:command].nil?
              player.output "What do you want to do with the log?"
              return
            else
              command = event[:command].downcase
            end

            case command
            when /^players?$/
              if event[:value]
                lines = event[:value].to_i
              else
                lines = 10
              end

              player.output tail('logs/player.log', lines)
            when 'server'
              if event[:value]
                lines = event[:value].to_i
              else
                lines = 10
              end

              player.output tail('logs/server.log', lines)
            when 'system'
              if event[:value]
                lines = event[:value].to_i
              else
                lines = 10
              end

              $LOG.dump

              player.output tail('logs/system.log', lines)
            when 'flush'
              log('Flushing log')
              $LOG.dump
              player.output 'Flushed log to disk.'
            when 'ultimate'
              ServerConfig[:log_level] = 3
              player.output "Log level now set to ULTIMATE."
            when 'high'
              ServerConfig[:log_level] = 2
              player.output "Log level now set to high."
            when 'low', 'normal'
              ServerConfig[:log_level] = 1
              player.output "Log level now set to normal."
            when 'off'
              ServerConfig[:log_level] = 0
              player.output "Logging mostly turned off. You may also want to turn off debugging."
            when 'debug'
              ServerConfig[:debug] = !$DEBUG
              player.output "Debug info is now: #{$DEBUG ? 'on' : 'off'}"
            else
              player.output 'Possible settings: Off, Debug, Normal, High, or Ultimate'
            end
          end

        end
        Aethyr::Extend::HandlerRegistry.register_handler(AlogHandler)
      end
    end
  end
end
