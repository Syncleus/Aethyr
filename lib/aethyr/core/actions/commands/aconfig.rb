require "aethyr/core/actions/commands/command_action"

module Aethyr
  module Core
    module Actions
      module Aconfig
        class AconfigCommand < Aethyr::Extend::CommandAction
          def initialize(actor, **data)
            super(actor, **data)
          end

          def action


            room = $manager.get_object(self[:agent].container)
            player = self[:agent]

            if self[:setting].nil?
              player.output "Current configuration:\n#{ServerConfig}"
              return
            end

            setting = self[:setting].downcase.to_sym

            if setting == :reload
              ServerConfig.reload
              player.output "Reloaded configuration:\n#{ServerConfig}"
              return
            elsif not ServerConfig.has_setting? setting
              player.output "No such setting."
              return
            end

            value = self[:value]
            if value =~ /^\d+$/
              value = value.to_i
            end

            ServerConfig[setting] = value

            player.output "New configuration:\n#{ServerConfig}"
          end

        end
      end
    end
  end
end
