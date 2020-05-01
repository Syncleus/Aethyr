require "aethyr/core/registry"
require "aethyr/core/commands/emotes/emote_handler"

module Aethyr
  module Core
    module Commands
      module Yes
        class YesHandler < Aethyr::Extend::EmoteHandler

          def self.create_help_entries
            help_entries = []

            command = "yes"
            see_also = nil
            syntax_formats = ["YES"]
            aliases = nil
            content =  <<'EOF'
Please see help for emote instead.
EOF
            help_entries.push(Aethyr::Core::Help::HelpEntry.new(command, content: content, syntax_formats: syntax_formats, see_also: see_also, aliases: aliases))

            return help_entries
          end


          def initialize(player)
            super(player, ["yes"], help_entries: YesHandler.create_help_entries)
          end

          def self.object_added(data)
            super(data, self)
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^(yes)( +([^()]*))?( +((.*)))?$/i
              object = $3
              post = $5
              yes({:object => object, :post => post})
            end
          end

          private
          def yes(event)

            room = $manager.get_object(@player.container)
            player = @player
            make_emote event, player, room do

              no_target do
                to_player  "\"Yes,\" you say, nodding."
                to_other "#{player.name} says, \"Yes\" and nods."
              end

              self_target do
                to_player  "You nod in agreement with yourself."
                to_other "#{player.name} nods at #{player.pronoun(:reflexive)} strangely."
                to_deaf_other event[:to_other]
              end

              target do
                to_player  "You nod in agreement with #{event.target.name}."
                to_target "#{player.name} nods in your direction, agreeing."
                to_other "#{player.name} nods in agreement with #{event.target.name}."
                to_deaf_other event[:to_other]
              end
            end

          end

        end
        Aethyr::Extend::HandlerRegistry.register_handler(YesHandler)
      end
    end
  end
end
