require "aethyr/core/registry"
require "aethyr/core/commands/emotes/emote_handler"

module Aethyr
  module Core
    module Commands
      module Grin
        class GrinHandler < Aethyr::Extend::EmoteHandler

          def self.create_help_entries
            help_entries = []

            command = "grin"
            see_also = nil
            syntax_formats = ["GRIN"]
            aliases = nil
            content =  <<'EOF'
Please see help for emote instead.
EOF
            help_entries.push(Aethyr::Core::Help::HelpEntry.new(command, content: content, syntax_formats: syntax_formats, see_also: see_also, aliases: aliases))

            return help_entries
          end


          def initialize(player)
            super(player, ["grin"], help_entries: GrinHandler.create_help_entries)
          end

          def self.object_added(data)
            super(data, self)
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^(grin)( +([^()]*))?( +((.*)))?$/i
              object = $3
              post = $5
              grin({:object => object, :post => post})
            end
          end

          private
          def grin(event)

            room = $manager.get_object(@player.container)
            player = @player

            make_emote event, player, room do

              no_target do
                to_player 'You grin widely, flashing all your teeth.'
                to_other "#{player.name} grins widely, flashing all #{player.pronoun(:possessive)} teeth."
                to_deaf_other event[:to_other]
              end

              self_target do
                to_player "You grin madly at yourself."
                to_other "#{player.name} grins madly at #{event.target.pronoun(:reflexive)}."
                to_deaf_other event[:to_other]
              end

              target do
                to_player "You give #{event.target.name} a wide grin."
                to_target "#{player.name} gives you a wide grin."
                to_deaf_target event[:to_target]
                to_other "#{player.name} gives #{event.target.name} a wide grin."
                to_deaf_other event[:to_other]
              end

            end
          end

        end
        Aethyr::Extend::HandlerRegistry.register_handler(GrinHandler)
      end
    end
  end
end
