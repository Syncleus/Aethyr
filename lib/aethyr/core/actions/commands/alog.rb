require "aethyr/core/actions/command_action"

module Aethyr
  module Core
    module Actions
      module Alog
        class AlogCommand < Aethyr::Extend::CommandAction
          def initialize(actor, **data)
            super(actor, **data)
          end

          def action
            event = @data

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
      end
    end
  end
end
