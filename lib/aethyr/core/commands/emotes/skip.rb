require "aethyr/core/registry"
require "aethyr/core/commands/emotes/emote_handler"

module Aethyr
  module Core
    module Commands
      module Skip
        class SkipHandler < Aethyr::Extend::EmoteHandler

          def self.create_help_entries
            help_entries = []

            command = "skip"
            see_also = nil
            syntax_formats = ["SKIP"]
            aliases = nil
            content =  <<'EOF'
Please see help for emote instead.
EOF
            help_entries.push(Aethyr::Core::Help::HelpEntry.new(command, content: content, syntax_formats: syntax_formats, see_also: see_also, aliases: aliases))

            return help_entries
          end


          def initialize(player)
            super(player, ["skip"], help_entries: SkipHandler.create_help_entries)
          end

          def self.object_added(data)
            super(data, self)
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^(skip)( +([^()]*))?( +((.*)))?$/i
              object = $3
              post = $5
              skip({:object => object, :post => post})
            end
          end

          private
          def skip(event)

            room = $manager.get_object(@player.container)
            player = @player

            make_emote event, player, room do

              no_target do
                to_player "You skip around cheerfully."
                to_other "#{player.name} skips around cheerfully."
                to_deaf_other "#{player.name} skips around cheerfully."
              end

              self_target do
                player.output 'How?'
              end

              target do
                to_player "You skip around #{event.target.name} cheerfully."
                to_target "#{player.name} skips around you cheerfully."
                to_other "#{player.name} skips around #{event.target.name} cheerfully."
                to_deaf_other "#{player.name} skips around #{event.target.name} cheerfully."
              end

            end
          end

        end
        Aethyr::Extend::HandlerRegistry.register_handler(SkipHandler)
      end
    end
  end
end
