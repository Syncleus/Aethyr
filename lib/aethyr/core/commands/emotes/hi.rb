require "aethyr/core/registry"
require "aethyr/core/commands/emotes/emote_handler"

module Aethyr
  module Core
    module Commands
      module Hi
        class HiHandler < Aethyr::Extend::EmoteHandler

          def self.create_help_entries
            help_entries = []

            command = "hi"
            see_also = nil
            syntax_formats = ["HI"]
            aliases = nil
            content =  <<'EOF'
Please see help for emote instead.
EOF
            help_entries.push(Aethyr::Core::Help::HelpEntry.new(command, content: content, syntax_formats: syntax_formats, see_also: see_also, aliases: aliases))

            return help_entries
          end


          def initialize(player)
            super(player, ["hi"], HiHandler.create_help_entries)
          end

          def self.object_added(data)
            super(data, self)
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^(hi)( +([^()]*))?( +((.*)))?$/i
              object = $3
              post = $5
              hi({:object => object, :post => post})
            end
          end

          private
          def hi(event)

            room = $manager.get_object(@player.container)
            player = @player

            make_emote event, player, room do

              no_target do
                to_player "\"Hi!\" you greet those around you."
                to_other "#{player.name} greets those around with a \"Hi!\""
              end

              self_target do
                player.output "Hi."
              end

              target do
                to_player "You say \"Hi!\" in greeting to #{event.target.name}."
                to_target "#{player.name} greets you with a \"Hi!\""
                to_other "#{player.name} greets #{event.target.name} with a hearty \"Hi!\""
              end
            end

          end

        end
        Aethyr::Extend::HandlerRegistry.register_handler(HiHandler)
      end
    end
  end
end
