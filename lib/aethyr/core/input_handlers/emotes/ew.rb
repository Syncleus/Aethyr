require "aethyr/core/registry"
require "aethyr/core/actions/commands/emotes/emote_handler"

module Aethyr
  module Core
    module Commands
      module Ew
        class EwHandler < Aethyr::Extend::EmoteHandler

          def self.create_help_entries
            help_entries = []

            command = "ew"
            see_also = nil
            syntax_formats = ["EW"]
            aliases = nil
            content =  <<'EOF'
Please see help for emote instead.
EOF
            help_entries.push(Aethyr::Core::Help::HelpEntry.new(command, content: content, syntax_formats: syntax_formats, see_also: see_also, aliases: aliases))

            return help_entries
          end


          def initialize(player)
            super(player, ["ew"], help_entries: EwHandler.create_help_entries)
          end

          def self.object_added(data)
            super(data, self)
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^(ew)( +([^()]*))?( +((.*)))?$/i
              object = $3
              post = $5
              ew({:object => object, :post => post})
            end
          end

          private
          def ew(event)

            room = $manager.get_object(@player.container)
            player = @player

            make_emote event, player, room do

              no_target do
                to_player "\"Ewww!\" you exclaim, looking disgusted."
                to_other "#{player.name} exclaims, \"Eww!!\" and looks disgusted."
                to_deaf_other "#{player.name} looks disgusted."
                to_blind_other "Somone exclaims, \"Eww!!\""
              end

              self_target do
                player.output "You think you are digusting?"
              end

              target do
                to_player "You glance at #{event.target.name} and say \"Ewww!\""
                to_target "#{player.name} glances in your direction and says, \"Ewww!\""
                to_deaf_other "#{player.name} gives #{event.target.name} a disgusted look."
                to_blind_other "Somone exclaims, \"Eww!!\""
                to_other "#{player.name} glances at #{event.target.name}, saying \"Ewww!\""
              end
            end
          end

        end
        Aethyr::Extend::HandlerRegistry.register_handler(EwHandler)
      end
    end
  end
end
