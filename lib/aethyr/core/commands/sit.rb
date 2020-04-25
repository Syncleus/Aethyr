require "aethyr/core/registry"
require "aethyr/core/commands/command_handler"

module Aethyr
  module Core
    module Commands
      module Sit
        class SitHandler < Aethyr::Extend::CommandHandler

          def self.create_help_entries
            help_entries = []

            command = "sit"
            see_also = ["STAND"]
            syntax_formats = ["SIT", "SIT ON <object>"]
            aliases = nil
            content =  <<'EOF'
Using this command, you can sit on things like chairs and benches. When used without an object, you will sit down on the ground.

Note that you must stand up before you can move anywhere.

Example:

SIT ON stool

EOF
            help_entries.push(Aethyr::Core::Help::HelpEntry.new(command, content: content, syntax_formats: syntax_formats, see_also: see_also, aliases: aliases))

            return help_entries
          end


          def initialize(player)
            super(player, ["sit"], SitHandler.create_help_entries)
          end

          def self.object_added(data)
            super(data, self)
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^sit\s+on\s+(.*)$/i, /^sit\s+(.*)$/i, /^sit$/i
              object = $1.strip if $1
              sit({:object => object})
            end
          end

          private
          def sit(event)

            room = $manager.get_object(@player.container)
            player = @player
            if not player.balance
              player.output "You cannot sit properly while unbalanced."
              return
            elsif event[:object].nil?
              if player.sitting?
                player.output('You are already sitting down.')
              elsif player.prone? and player.sit
                event[:to_player] = 'You stand up then sit on the ground.'
                event[:to_other] = "#{player.name} stands up then sits down on the ground."
                event[:to_deaf_other] = event[:to_other]
                room.output(event)
              elsif player.sit
                event[:to_player] = 'You sit down on the ground.'
                event[:to_other] = "#{player.name} sits down on the ground."
                event[:to_deaf_other] = event[:to_other]
                room.out_event(event)
              else
                player.output('You are unable to sit down.')
              end
            else
              object = $manager.find(event[:object], player.room)

              if object.nil?
                player.output('What do you want to sit on?')
              elsif not object.can? :sittable?
                player.output("You cannot sit on #{object.name}.")
              elsif object.occupied_by? player
                player.output("You are already sitting there!")
              elsif not object.has_room?
                player.output("The #{object.generic} #{object.plural? ? "are" : "is"} already occupied.")
              elsif player.sit(object)
                object.sat_on_by(player)
                event[:to_player] = "You sit down on #{object.name}."
                event[:to_other] = "#{player.name} sits down on #{object.name}."
                event[:to_deaf_other] = event[:to_other]
                room.out_event(event)
              else
                player.output('You are unable to sit down.')
              end
            end
          end

        end
        Aethyr::Extend::HandlerRegistry.register_handler(SitHandler)
      end
    end
  end
end
