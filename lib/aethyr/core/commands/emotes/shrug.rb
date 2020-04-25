require "aethyr/core/registry"
require "aethyr/core/commands/emotes/emote_handler"

module Aethyr
  module Core
    module Commands
      module Shrug
        class ShrugHandler < Aethyr::Extend::EmoteHandler

          def self.create_help_entries
            help_entries = []

            command = "shrug"
            see_also = nil
            syntax_formats = ["SHRUG"]
            aliases = nil
            content =  <<'EOF'
Please see help for emote instead.
EOF
            help_entries.push(Aethyr::Core::Help::HelpEntry.new(command, content: content, syntax_formats: syntax_formats, see_also: see_also, aliases: aliases))

            return help_entries
          end


          def initialize(player)
            super(player, ["shrug"], ShrugHandler.create_help_entries)
          end

          def self.object_added(data)
            super(data, self)
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^(shrug)( +([^()]*))?( +((.*)))?$/i
              object = $3
              post = $5
              shrug({:object => object, :post => post})
            end
          end

          private
          def shrug(event)

            room = $manager.get_object(@player.container)
            player = @player

            make_emote event, player, room do

              no_target do
                to_player "You shrug your shoulders."
                to_other "#{player.name} shrugs #{player.pronoun(:possessive)} shoulders."
                to_deaf_other event[:to_other]
              end

              self_target do
                player.output "Don't just shrug yourself off like that!"

              end

              target do
                to_player  "You give #{event.target.name} a brief shrug."
                to_target "#{player.name} gives you a brief shrug."
                to_other "#{player.name} gives #{event.target.name} a brief shrug."
                to_deaf_other event[:to_other]
                to_deaf_target event[:to_target]
              end
            end

          end

        end
        Aethyr::Extend::HandlerRegistry.register_handler(ShrugHandler)
      end
    end
  end
end
