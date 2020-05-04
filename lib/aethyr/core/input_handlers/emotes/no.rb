require "aethyr/core/registry"
require "aethyr/core/actions/commands/emotes/emote_handler"

module Aethyr
  module Core
    module Commands
      module No
        class NoHandler < Aethyr::Extend::EmoteHandler

          def self.create_help_entries
            help_entries = []

            command = "no"
            see_also = nil
            syntax_formats = ["NO"]
            aliases = nil
            content =  <<'EOF'
Please see help for emote instead.
EOF
            help_entries.push(Aethyr::Core::Help::HelpEntry.new(command, content: content, syntax_formats: syntax_formats, see_also: see_also, aliases: aliases))

            return help_entries
          end


          def initialize(player)
            super(player, ["no"], help_entries: NoHandler.create_help_entries)
          end

          def self.object_added(data)
            super(data, self)
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^(no)( +([^()]*))?( +((.*)))?$/i
              object = $3
              post = $5
              no({:object => object, :post => post})
            end
          end

          private
          def no(event)

            room = $manager.get_object(@player.container)
            player = @player
            make_emote event, player, room do
              no_target do
                to_player  "\"No,\" you say, shaking your head."
                to_other "#{player.name} says, \"No\" and shakes #{player.pronoun(:possessive)} head."
              end
              self_target do
                to_player  "You shake your head negatively in your direction. You are kind of strange."
                to_other "#{player.name} shakes #{player.pronoun(:possessive)} head at #{player.pronoun(:reflexive)}."
                to_deaf_other event[:to_other]
              end
              target do
                to_player  "You shake your head, disagreeing with #{event.target.name}."
                to_target "#{player.name} shakes #{player.pronoun(:possessive)} head in your direction, disagreeing."
                to_other "#{player.name} shakes #{player.pronoun(:possessive)} head in disagreement with #{event.target.name}."
                to_deaf_other event[:to_other]
              end
            end

          end

        end
        Aethyr::Extend::HandlerRegistry.register_handler(NoHandler)
      end
    end
  end
end
