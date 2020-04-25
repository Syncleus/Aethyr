require "aethyr/core/registry"
require "aethyr/core/commands/emotes/emote_handler"

module Aethyr
  module Core
    module Commands
      module Sigh
        class SighHandler < Aethyr::Extend::EmoteHandler

          def self.create_help_entries
            help_entries = []

            command = "sigh"
            see_also = nil
            syntax_formats = ["SIGH"]
            aliases = nil
            content =  <<'EOF'
Please see help for emote instead.
EOF
            help_entries.push(Aethyr::Core::Help::HelpEntry.new(command, content: content, syntax_formats: syntax_formats, see_also: see_also, aliases: aliases))

            return help_entries
          end


          def initialize(player)
            super(player, ["sigh"], SighHandler.create_help_entries)
          end

          def self.object_added(data)
            super(data, self)
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^(sigh)( +([^()]*))?( +((.*)))?$/i
              object = $3
              post = $5
              sigh({:object => object, :post => post})
            end
          end

          private
          def sigh(event)

            room = $manager.get_object(@player.container)
            player = @player

            make_emote event, player, room do

              no_target do
                to_player "You exhale, sighing deeply."
                to_other "#{player.name} breathes out a deep sigh."
              end

              self_target do
                to_player "You sigh at your misfortunes."
                to_other "#{player.name} sighs at #{player.pronoun(:possessive)} own misfortunes."
              end

              target do
                to_player "You sigh in #{event.target.name}'s general direction."
                to_target "#{player.name} heaves a sigh in your direction."
                to_other "#{player.name} sighs heavily in #{event.target.name}'s direction."
              end
            end

          end

        end
        Aethyr::Extend::HandlerRegistry.register_handler(SighHandler)
      end
    end
  end
end
