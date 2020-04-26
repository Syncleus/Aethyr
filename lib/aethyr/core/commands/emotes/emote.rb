require "aethyr/core/registry"
require "aethyr/core/commands/emotes/emote_handler"

module Aethyr
  module Core
    module Commands
      module Emote
        class EmoteHandler < Aethyr::Extend::EmoteHandler

          def self.create_help_entries
            help_entries = []

            command = "emote"
            see_also = nil
            syntax_formats = ["EMOTE [action]"]
            aliases = nil
            content =  <<'EOF'
The emote command is used to convey actions to an entire room besides just talking or premade emotes (also called socials).
The simplest way to use this command is by simply typing EMOTE then your actions:

If I am Joe and I type:
EMOTE runs about wildly

It will result in the room seeing:
Joe runs about wildly.

However, there are more complex uses. Try using $me to substitute for your name:

If I am Joe and I type:
EMOTE eyes crazy, $me runs about wildly.

It will result in the room seeing:
Eyes crazy, Joe runs about wildly.


You may also use $name to substitute other people's names into your emote.

If I am Joe and I type:
EMOTE bonks $sarah on the head

The room sees:
Joe bonks Sarah on the head.

Sarah sees:
Joe bonks you on the head.

Note that you cannot combine $me and $name in the same emote.
EOF
            help_entries.push(Aethyr::Core::Help::HelpEntry.new(command, content: content, syntax_formats: syntax_formats, see_also: see_also, aliases: aliases))

            return help_entries
          end


          def initialize(player)
            super(player, ["emote"], help_entries: EmoteHandler.create_help_entries)
          end

          def self.object_added(data)
            super(data, self)
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^emote\s+(.*)/i
              show = $1
              emote({:show => show})
            end
          end

          private
          def emote(event)

            room = $manager.get_object(@player.container)
            player = @player
            action = event[:show].strip

            unless ['!', '.', '?', '"'].include? action[-1..-1]
              action << '.'
            end

            if action =~ /\$me[^a-zA-Z]/i
              action.gsub!(/\$me/i, player.name)
              action[0,1] = action[0,1].capitalize
              show = action
            elsif action.include? '$'
              people = []
              action.gsub!(/\$(\w+)/) do |name|
                target = room.find($1)
                people << target unless target.nil?
                target ? target.name : 'no one'
              end

              people.each do |person|
                out = action.gsub(person.name, 'you')
                person.output("#{player.name} #{out}", message_type = :chat) unless person.can? :blind and person.blind?
              end

              room.output("#{player.name} #{action}", player, *people)
              player.output("You emote: #{player.name} #{action}")
            else
              show = "#{player.name} #{action}"
            end

            if show
              event[:message_type] = :chat
              event[:to_player] = "You emote: #{show}"
              event[:to_other] = show
              room.out_event event
            end
          end

        end
        Aethyr::Extend::HandlerRegistry.register_handler(EmoteHandler)
      end
    end
  end
end
