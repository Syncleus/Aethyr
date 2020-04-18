require "aethyr/core/registry"
require "aethyr/core/commands/command_handler"

module Aethyr
  module Core
    module Commands
      module Aconfig
        class AconfigHandler < Aethyr::Extend::CommandHandler
          def initialize(player)
            super(player, ["aconfig"])
          end

          def self.object_added(data)
            return unless data[:game_object].is_a? Player
            data[:game_object].subscribe(AconfigHandler.new(data[:game_object]))
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^aconfig(\s+reload)?$/i
              setting = "reload" if $1
              aconfig({:setting => setting})
            when /^aconfig\s+(\w+)\s+(.*)$/i
              setting = $1
              value = $2
              aconfig({:setting => setting, :value => value})
            when /^help (aconfig)$/i
              action_help_aconfig({})
            end
          end

          private
          def action_help_aconfig(event)
            @player.output <<'EOF'
Sorry no help has been written for this command yet
EOF
          end


          def aconfig(event)

            room = $manager.get_object(@player.container)
            player = @player

            if event[:setting].nil?
              player.output "Current configuration:\n#{ServerConfig}"
              return
            end

            setting = event[:setting].downcase.to_sym

            if setting == :reload
              ServerConfig.reload
              player.output "Reloaded configuration:\n#{ServerConfig}"
              return
            elsif not ServerConfig.has_setting? setting
              player.output "No such setting."
              return
            end

            value = event[:value]
            if value =~ /^\d+$/
              value = value.to_i
            end

            ServerConfig[setting] = value

            player.output "New configuration:\n#{ServerConfig}"
          end

        end
        Aethyr::Extend::HandlerRegistry.register_handler(AconfigHandler)
      end
    end
  end
end
