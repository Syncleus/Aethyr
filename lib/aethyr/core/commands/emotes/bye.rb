require "aethyr/core/registry"
require "aethyr/core/commands/emotes/emote_handler"

module Aethyr
  module Core
    module Commands
      module Bye
        class ByeHandler < Aethyr::Extend::EmoteHandler

          def self.create_help_entries
            help_entries = []

            command = "bye"
            see_also = nil
            syntax_formats = ["BYE"]
            aliases = nil
            content =  <<'EOF'
Please see help for emote instead.
EOF
            help_entries.push(Aethyr::Core::Help::HelpEntry.new(command, content: content, syntax_formats: syntax_formats, see_also: see_also, aliases: aliases))

            return help_entries
          end


          def initialize(player)
            super(player, ["bye"], ByeHandler.create_help_entries)
          end

          def self.object_added(data)
            super(data, self)
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^(bye)( +([^()]*))?( +((.*)))?$/i
              object = $3
              post = $5
              bye({:object => object, :post => post})
            end
          end

          private
          def bye(event)

            room = $manager.get_object(@player.container)
            player = @player

            make_emote event, player, room do

              no_target do
                to_player "You say a hearty \"Goodbye!\" to those around you."
                to_other "#{player.name} says a hearty \"Goodbye!\""
              end

              self_target do
                player.output "Goodbye."
              end

              target do
                to_player "You say \"Goodbye!\" to #{event.target.name}."
                to_target "#{player.name} says \"Goodbye!\" to you."
                to_other "#{player.name} says \"Goodbye!\" to #{event.target.name}"
              end
            end

          end

        end
        Aethyr::Extend::HandlerRegistry.register_handler(ByeHandler)
      end
    end
  end
end
