require "aethyr/core/registry"
require "aethyr/core/commands/emotes/emote_handler"

module Aethyr
  module Core
    module Commands
      module Ponder
        class PonderHandler < Aethyr::Extend::EmoteHandler

          def self.create_help_entries
            help_entries = []

            command = "ponder"
            see_also = nil
            syntax_formats = ["PONDER"]
            aliases = nil
            content =  <<'EOF'
Please see help for emote instead.
EOF
            help_entries.push(Aethyr::Core::Help::HelpEntry.new(command, content: content, syntax_formats: syntax_formats, see_also: see_also, aliases: aliases))

            return help_entries
          end


          def initialize(player)
            super(player, ["ponder"], PonderHandler.create_help_entries)
          end

          def self.object_added(data)
            super(data, self)
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^(ponder)( +([^()]*))?( +((.*)))?$/i
              object = $3
              post = $5
              ponder({:object => object, :post => post})
            end
          end

          private
          def ponder(event)

            room = $manager.get_object(@player.container)
            player = @player

            make_emote event, player, room do

              no_target do
                to_player "You ponder that idea for a moment."
                to_other "#{player.name} looks thoughtful as #{player.pronoun} ponders a thought."
                to_deaf_other event[:to_other]
              end

              self_target do
                to_player  "You look down in deep thought at your navel."
                to_other "#{player.name} looks down thoughtfully at #{player.pronoun(:possessive)} navel."
                to_deaf_other event[:to_other]
              end

              target do
                to_player "You give #{event.target.name} a thoughtful look as you reflect and ponder."
                to_target "#{player.name} gives you a thoughtful look and seems to be reflecting upon something."
                to_other "#{player.name} gives #{event.target.name} a thoughtful look and appears to be absorbed in reflection."
                to_deaf_other event[:to_other]
              end
            end
          end

        end
        Aethyr::Extend::HandlerRegistry.register_handler(PonderHandler)
      end
    end
  end
end
