require "aethyr/core/registry"
require "aethyr/core/actions/commands/emotes/emote_handler"

module Aethyr
  module Core
    module Commands
      module Hug
        class HugHandler < Aethyr::Extend::EmoteHandler

          def self.create_help_entries
            help_entries = []

            command = "hug"
            see_also = nil
            syntax_formats = ["HUG"]
            aliases = nil
            content =  <<'EOF'
Please see help for emote instead.
EOF
            help_entries.push(Aethyr::Core::Help::HelpEntry.new(command, content: content, syntax_formats: syntax_formats, see_also: see_also, aliases: aliases))

            return help_entries
          end


          def initialize(player)
            super(player, ["hug"], help_entries: HugHandler.create_help_entries)
          end

          def self.object_added(data)
            super(data, self)
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^(hug)( +([^()]*))?( +((.*)))?$/i
              object = $3
              post = $5
              hug({:object => object, :post => post})
            end
          end

          private
          def hug(event)

            room = $manager.get_object(@player.container)
            player = @player

            make_emote event, player, room do

              no_target do
                player.output "Who are you trying to hug?"
              end

              self_target do
                to_player 'You wrap your arms around yourself and give a tight squeeze.'
                to_other "#{player.name} gives #{player.pronoun(:reflexive)} a tight squeeze."
                to_deaf_other event[:to_other]
              end

              target do
                to_player "You give #{event.target.name} a great big hug."
                to_target "#{player.name} gives you a great big hug."
                to_other "#{player.name} gives #{event.target.name} a great big hug."
                to_blind_target "Someone gives you a great big hug."
                to_deaf_other event[:to_other]
              end
            end
          end

        end
        Aethyr::Extend::HandlerRegistry.register_handler(HugHandler)
      end
    end
  end
end
