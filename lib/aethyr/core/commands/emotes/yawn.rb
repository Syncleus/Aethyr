require "aethyr/core/registry"
require "aethyr/core/commands/emotes/emote_handler"

module Aethyr
  module Core
    module Commands
      module Yawn
        class YawnHandler < Aethyr::Extend::EmoteHandler

          def self.create_help_entries
            help_entries = []

            command = "yawn"
            see_also = nil
            syntax_formats = ["YAWN"]
            aliases = nil
            content =  <<'EOF'
Please see help for emote instead.
EOF
            help_entries.push(Aethyr::Core::Help::HelpEntry.new(command, content: content, syntax_formats: syntax_formats, see_also: see_also, aliases: aliases))

            return help_entries
          end


          def initialize(player)
            super(player, ["yawn"], help_entries: YawnHandler.create_help_entries)
          end

          def self.object_added(data)
            super(data, self)
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^(yawn)( +([^()]*))?( +((.*)))?$/i
              object = $3
              post = $5
              yawn({:object => object, :post => post})
            end
          end

          private
          def yawn(event)

            room = $manager.get_object(@player.container)
            player = @player

            make_emote event, player, room do

              no_target do
                to_player "You open your mouth in a wide yawn, then exhale loudly."
                to_other "#{player.name} opens #{player.pronoun(:possessive)} mouth in a wide yawn, then exhales loudly."
              end

              self_target do
                to_player "You yawn at how boring you are."
                to_other "#{player.name} yawns at #{player.pronoun(:reflexive)}."
                to_deaf_other event[:to_other]
              end

              target do
                to_player "You yawn at #{event.target.name}, bored out of your mind."
                to_target "#{player.name} yawns at you, finding you boring."
                to_other "#{player.name} yawns at how boring #{event.target.name} is."
                to_deaf_other event[:to_other]
              end
            end

          end

        end
        Aethyr::Extend::HandlerRegistry.register_handler(YawnHandler)
      end
    end
  end
end
