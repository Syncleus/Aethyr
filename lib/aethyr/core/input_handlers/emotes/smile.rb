require "aethyr/core/registry"
require "aethyr/core/actions/commands/emotes/emote_handler"

module Aethyr
  module Core
    module Commands
      module Smile
        class SmileHandler < Aethyr::Extend::EmoteHandler

          def self.create_help_entries
            help_entries = []

            command = "smile"
            see_also = nil
            syntax_formats = ["SMILE"]
            aliases = nil
            content =  <<'EOF'
Please see help for emote instead.
EOF
            help_entries.push(Aethyr::Core::Help::HelpEntry.new(command, content: content, syntax_formats: syntax_formats, see_also: see_also, aliases: aliases))

            return help_entries
          end


          def initialize(player)
            super(player, ["smile"], help_entries: SmileHandler.create_help_entries)
          end

          def self.object_added(data)
            super(data, self)
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^(smile)( +([^()]*))?( +((.*)))?$/i
              object = $3
              post = $5
              smile({:object => object, :post => post})
            end
          end

          private
          def smile(event)

            room = $manager.get_object(@player.container)
            player = @player

            make_emote event, player, room do

              self_target do
                to_player "You smile happily at yourself."
                to_other "#{player.name} smiles at #{player.pronoun(:reflexive)} sillily."
              end

              target do
                to_player "You smile at #{event.target.name} kindly."
                to_target "#{player.name} smiles at you kindly."
                to_other "#{player.name} smiles at #{event.target.name} kindly."
              end

              no_target do
                to_player "You smile happily."
                to_other "#{player.name} smiles happily."
              end
            end
          end

        end
        Aethyr::Extend::HandlerRegistry.register_handler(SmileHandler)
      end
    end
  end
end
