require "aethyr/core/actions/commands/emotes/brb"
require "aethyr/core/registry"
require "aethyr/core/input_handlers/emotes/emote_handler"

module Aethyr
  module Core
    module Commands
      module Brb
        class BrbHandler < Aethyr::Extend::EmoteHandler

          def self.create_help_entries
            help_entries = []

            command = "brb"
            see_also = nil
            syntax_formats = ["BRB"]
            aliases = nil
            content =  <<'EOF'
Please see help for emote instead.
EOF
            help_entries.push(Aethyr::Core::Help::HelpEntry.new(command, content: content, syntax_formats: syntax_formats, see_also: see_also, aliases: aliases))

            return help_entries
          end


          def initialize(player)
            super(player, ["brb"], help_entries: BrbHandler.create_help_entries)
          end

          def self.object_added(data)
            super(data, self)
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^(brb)( +([^()]*))?( +((.*)))?$/i
              object = $3
              post = $5
              $manager.submit_action(Aethyr::Core::Actions::Brb::BrbCommand.new(@player, :object => object, :post => post))
            end
          end

          private

        end
        Aethyr::Extend::HandlerRegistry.register_handler(BrbHandler)
      end
    end
  end
end
