require "aethyr/core/actions/commands/emotes/cheer"
require "aethyr/core/registry"
require "aethyr/core/input_handlers/emotes/emote_handler"

module Aethyr
  module Core
    module Commands
      module Cheer
        class CheerHandler < Aethyr::Extend::EmoteHandler

          def self.create_help_entries
            help_entries = []

            command = "cheer"
            see_also = nil
            syntax_formats = ["CHEER"]
            aliases = nil
            content =  <<'EOF'
Please see help for emote instead.
EOF
            help_entries.push(Aethyr::Core::Help::HelpEntry.new(command, content: content, syntax_formats: syntax_formats, see_also: see_also, aliases: aliases))

            return help_entries
          end


          def initialize(player)
            super(player, ["cheer"], help_entries: CheerHandler.create_help_entries)
          end

          def self.object_added(data)
            super(data, self)
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^(cheer)( +([^()]*))?( +((.*)))?$/i
              object = $3
              post = $5
              $manager.submit_action(Aethyr::Core::Actions::Cheer::CheerCommand.new(@player, :object => object, :post => post))
            end
          end

          private

        end
        Aethyr::Extend::HandlerRegistry.register_handler(CheerHandler)
      end
    end
  end
end
