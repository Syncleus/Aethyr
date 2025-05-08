require "aethyr/core/actions/commands/areaction"
require "aethyr/core/registry"
require "aethyr/core/input_handlers/admin/admin_handler"

module Aethyr
  module Core
    module Commands
      module Areact
        class AreactHandler < Aethyr::Extend::AdminHandler

          def self.create_help_entries
            help_entries = []

            command = "areact"
            see_also = nil
            syntax_formats = ["AREACT LOAD [OBJECT] [FILE]", "AREACT [RELOAD|CLEAR] [OBJECT]"]
            aliases = nil
            content =  <<'EOF'
Sorry no help has been written for this command yet
EOF
            help_entries.push(Aethyr::Core::Help::HelpEntry.new(command, content: content, syntax_formats: syntax_formats, see_also: see_also, aliases: aliases))

            return help_entries
          end


          def initialize(player)
            super(player, ["areact"], help_entries: AreactHandler.create_help_entries)
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
              $manager.submit_action(Aethyr::Core::Actions::Areaction::AreactionCommand.new(@player, :object => object, :command => command, :file => file))
            when /^areact\s+(reload|clear|show)\s+(.*?)$/i
              object = $2
              command = $1
              $manager.submit_action(Aethyr::Core::Actions::Areaction::AreactionCommand.new(@player, :object => object, :command => command))
            when /^areact\s+(add|delete)\s+(.*?)\s+(\w+)$/i
              object = $2
              command = $1
              action_name = $3
              $manager.submit_action(Aethyr::Core::Actions::Areaction::AreactionCommand.new(@player, :object => object, :command => command, :action_name => action_name))
            end
          end

          private

        end
        Aethyr::Extend::HandlerRegistry.register_handler(AreactHandler)
      end
    end
  end
end
