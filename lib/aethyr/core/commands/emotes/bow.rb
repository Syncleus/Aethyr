require "aethyr/core/registry"
require "aethyr/core/commands/emotes/emote_handler"

module Aethyr
  module Core
    module Commands
      module Bow
        class BowHandler < Aethyr::Extend::EmoteHandler

          def self.create_help_entries
            help_entries = []

            command = "bow"
            see_also = nil
            syntax_formats = ["BOW"]
            aliases = nil
            content =  <<'EOF'
Please see help for emote instead.
EOF
            help_entries.push(Aethyr::Core::Help::HelpEntry.new(command, content: content, syntax_formats: syntax_formats, see_also: see_also, aliases: aliases))

            return help_entries
          end


          def initialize(player)
            super(player, ["bow"], help_entries: BowHandler.create_help_entries)
          end

          def self.object_added(data)
            super(data, self)
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^(bow)( +([^()]*))?( +((.*)))?$/i
              object = $3
              post = $5
              bow({:object => object, :post => post})
            end
          end

          private
          def bow(event)

            room = $manager.get_object(@player.container)
            player = @player

            make_emote event, player, room do

              no_target do
                to_player "You bow deeply and respectfully."
                to_other "#{player.name} bows deeply and respectfully."
                to_deaf_other event[:to_other]
              end

              self_target do
                player.output  "Huh?"
              end

              target do
                to_player  "You bow respectfully towards #{event.target.name}."
                to_target "#{player.name} bows respectfully before you."
                to_other "#{player.name} bows respectfully towards #{event.target.name}."
                to_deaf_other event[:to_other]
              end
            end

          end

        end
        Aethyr::Extend::HandlerRegistry.register_handler(BowHandler)
      end
    end
  end
end
