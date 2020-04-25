require "aethyr/core/registry"
require "aethyr/core/commands/emotes/emote_handler"

module Aethyr
  module Core
    module Commands
      module Snicker
        class SnickerHandler < Aethyr::Extend::EmoteHandler

          def self.create_help_entries
            help_entries = []

            command = "snicker"
            see_also = nil
            syntax_formats = ["SNICKER"]
            aliases = nil
            content =  <<'EOF'
Please see help for emote instead.
EOF
            help_entries.push(Aethyr::Core::Help::HelpEntry.new(command, content: content, syntax_formats: syntax_formats, see_also: see_also, aliases: aliases))

            return help_entries
          end


          def initialize(player)
            super(player, ["snicker"], SnickerHandler.create_help_entries)
          end

          def self.object_added(data)
            super(data, self)
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^(snicker)( +([^()]*))?( +((.*)))?$/i
              object = $3
              post = $5
              snicker({:object => object, :post => post})
            end
          end

          private
          def snicker(event)

            room = $manager.get_object(@player.container)
            player = @player

            make_emote event, player, room do

              no_target do
                to_player  "You snicker softly to yourself."
                to_other "You hear #{player.name} snicker softly."
                to_blind_other "You hear someone snicker softly."
              end

              self_target do
                player.output "What are you snickering about?"
              end

              target do
                to_player  "You snicker at #{event.target.name} under your breath."
                to_target "#{player.name} snickers at you under #{player.pronoun(:possessive)} breath."
                to_other "#{player.name} snickers at #{event.target.name} under #{player.pronoun(:possessive)} breath."
              end
            end

          end

        end
        Aethyr::Extend::HandlerRegistry.register_handler(SnickerHandler)
      end
    end
  end
end
