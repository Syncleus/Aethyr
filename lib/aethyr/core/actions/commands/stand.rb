require "aethyr/core/registry"
require "aethyr/core/actions/commands/command_handler"

module Aethyr
  module Core
    module Commands
      module Stand
        class StandHandler < Aethyr::Extend::CommandHandler

          def self.create_help_entries
            help_entries = []

            command = "stand"
            see_also = ["SIT"]
            syntax_formats = ["STAND"]
            aliases = nil
            content =  <<'EOF'
Stand up if you are sitting down.

EOF
            help_entries.push(Aethyr::Core::Help::HelpEntry.new(command, content: content, syntax_formats: syntax_formats, see_also: see_also, aliases: aliases))

            return help_entries
          end


          def initialize(player)
            super(player, ["stand"], help_entries: StandHandler.create_help_entries)
          end

          def self.object_added(data)
            super(data, self)
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^stand$/i
              stand({})
            end
          end

          private
          def stand(event)

            room = $manager.get_object(@player.container)
            player = @player
            if not player.prone?
              player.output('You are already on your feet.')
              return
            elsif not player.balance
              player.output "You cannot stand while unbalanced."
              return
            end

            if player.sitting?
              object = $manager.find(player.sitting_on, room)
            else
              object = $manager.find(player.lying_on, room)
            end

            if player.stand
              event[:to_player] = 'You rise to your feet.'
              event[:to_other] = "#{player.name} stands up."
              event[:to_deaf_other] = event[:to_other]
              room.out_event(event)
              object.evacuated_by(player) unless object.nil?
            else
              player.output('You are unable to stand up.')
            end
          end

        end
        Aethyr::Extend::HandlerRegistry.register_handler(StandHandler)
      end
    end
  end
end
