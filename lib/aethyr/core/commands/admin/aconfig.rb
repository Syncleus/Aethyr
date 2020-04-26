require "aethyr/core/registry"
require "aethyr/core/commands/admin/admin_handler"

module Aethyr
  module Core
    module Commands
      module Aconfig
        class AconfigHandler < Aethyr::Extend::AdminHandler

          def self.create_help_entries
            help_entries = []

            command = "aconfig"
            see_also = nil
            syntax_formats = ["ACONFIG", "ACONFIG RELOAD", "ACONFIG [SETTING] [VALUE]"]
            aliases = nil
            content =  <<'EOF'
Sorry no help has been written for this command yet
EOF
            help_entries.push(Aethyr::Core::Help::HelpEntry.new(command, content: content, syntax_formats: syntax_formats, see_also: see_also, aliases: aliases))

            return help_entries
          end


          def initialize(player)
            super(player, ["aconfig"], help_entries: AconfigHandler.create_help_entries)
          end

          def self.object_added(data)
            super(data, self)
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
            end
          end

          private
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
