require "aethyr/core/actions/commands/ainfo"
require "aethyr/core/registry"
require "aethyr/core/input_handlers/admin/admin_handler"

module Aethyr
  module Core
    module Commands
      module Ainfo
        class AinfoHandler < Aethyr::Extend::AdminHandler

          def self.create_help_entries
            help_entries = []

            command = "ainfo"
            see_also = nil
            syntax_formats = ["AINFO SET [OBJECT] @[ATTRIBUTE] [VALUE]", "AINFO DELETE [OBJECT] @[ATTRIBUTE]", "AINFO [SHOW|CLEAR] [OBJECT]"]
            aliases = nil
            content =  <<'EOF'
Sorry no help has been written for this command yet
EOF
            help_entries.push(Aethyr::Core::Help::HelpEntry.new(command, content: content, syntax_formats: syntax_formats, see_also: see_also, aliases: aliases))

            return help_entries
          end


          def initialize(player)
            super(player, ["ainfo"], help_entries: AinfoHandler.create_help_entries)
          end

          def self.object_added(data)
            super(data, self)
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^ainfo\s+set\s+(.+)\s+@((\w|\.|\_)+)\s+(.*?)$/i
              command = "set"
              object = $1
              attrib = $2
              value = $4
              $manager.submit_action(Aethyr::Core::Actions::Ainfo::AinfoCommand.new(@player, :command => command, :object => object, :attrib => attrib, :value => value))
            when /^ainfo\s+(show|clear)\s+(.*)$/i
              object = $2
              command = $1
              $manager.submit_action(Aethyr::Core::Actions::Ainfo::AinfoCommand.new(@player, :object => object, :command => command))
            when /^ainfo\s+(del|delete)\s+(.+)\s+@((\w|\.|\_)+)$/i
              command = "delete"
              object = $2
              attrib = $3
              $manager.submit_action(Aethyr::Core::Actions::Ainfo::AinfoCommand.new(@player, :command => command, :object => object, :attrib => attrib))
            end
          end

          private

        end
        Aethyr::Extend::HandlerRegistry.register_handler(AinfoHandler)
      end
    end
  end
end
