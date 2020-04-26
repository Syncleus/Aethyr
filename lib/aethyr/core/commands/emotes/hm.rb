require "aethyr/core/registry"
require "aethyr/core/commands/emotes/emote_handler"

module Aethyr
  module Core
    module Commands
      module Hm
        class HmHandler < Aethyr::Extend::EmoteHandler

          def self.create_help_entries
            help_entries = []

            command = "hm"
            see_also = nil
            syntax_formats = ["HM"]
            aliases = nil
            content =  <<'EOF'
Please see help for emote instead.
EOF
            help_entries.push(Aethyr::Core::Help::HelpEntry.new(command, content: content, syntax_formats: syntax_formats, see_also: see_also, aliases: aliases))

            return help_entries
          end


          def initialize(player)
            super(player, ["hm"], help_entries: HmHandler.create_help_entries)
          end

          def self.object_added(data)
            super(data, self)
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^(hm)( +([^()]*))?( +((.*)))?$/i
              object = $3
              post = $5
              hm({:object => object, :post => post})
            end
          end

          private
          def hm(event)

            room = $manager.get_object(@player.container)
            player = @player

            make_emote event, player, room do

              no_target do
                to_other "#{player.name} purses #{player.pronoun(:possessive)} lips thoughtfully and says, \"Hmmm...\""
                to_player "You purse your lips thoughtfully and say, \"Hmmm...\""
              end

              self_target do
                to_other "#{player.name} looks down at #{player.pronoun(:reflexive)} and says, \"Hmmm...\""
                to_player "You look down at yourself and say, \"Hmmm...\""
              end

              target do
                to_other "#{player.name} purses #{player.pronoun(:possessive)} lips as #{player.pronoun} looks thoughtfully at #{event.target.name} and says, \"Hmmm...\""
                to_player "You purse your lips as you look thoughtfully at #{event.target.name} and say, \"Hmmm...\""
                to_target "#{player.name} purses #{player.pronoun(:possessive)} lips as #{player.pronoun} looks thoughtfully at you and says, \"Hmmm...\""
              end
            end

          end

        end
        Aethyr::Extend::HandlerRegistry.register_handler(HmHandler)
      end
    end
  end
end
