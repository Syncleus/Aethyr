require "aethyr/core/registry"
require "aethyr/core/commands/emotes/emote_handler"

module Aethyr
  module Core
    module Commands
      module Curtsey
        class CurtseyHandler < Aethyr::Extend::EmoteHandler

          def self.create_help_entries
            help_entries = []

            command = "curtsey"
            see_also = nil
            syntax_formats = ["CURTSEY"]
            aliases = nil
            content =  <<'EOF'
Please see help for emote instead.
EOF
            help_entries.push(Aethyr::Core::Help::HelpEntry.new(command, content: content, syntax_formats: syntax_formats, see_also: see_also, aliases: aliases))

            return help_entries
          end


          def initialize(player)
            super(player, ["curtsey"], CurtseyHandler.create_help_entries)
          end

          def self.object_added(data)
            super(data, self)
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^(curtsey)( +([^()]*))?( +((.*)))?$/i
              object = $3
              post = $5
              curtsey({:object => object, :post => post})
            end
          end

          private
          def curtsey(event)

            room = $manager.get_object(@player.container)
            player = @player

            make_emote event, player, room do

              no_target do
                to_player  "You perform a very graceful curtsey."
                to_other "#{player.name} curtseys quite gracefully."
                to_deaf_other event[:to_other]
              end

              self_target do
                player.output "Hm? How do you do that?"
              end

              target do
                to_player "You curtsey gracefully and respectfully towards #{event.target.name}."
                to_target "#{player.name} curtseys gracefully and respectfully in your direction."
                to_other "#{player.name} curtseys gracefully and respectfully towards #{event.target.name}."
                to_deaf_other event[:to_other]
              end

            end
          end

        end
        Aethyr::Extend::HandlerRegistry.register_handler(CurtseyHandler)
      end
    end
  end
end
