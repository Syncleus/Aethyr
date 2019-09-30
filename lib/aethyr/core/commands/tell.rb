require "aethyr/core/registry"
require "aethyr/core/commands/command_handler"

module Aethyr
  module Core
    module Commands
      module Tell
        class TellHandler < Aethyr::Extend::CommandHandler
          def initialize(player)
            super(player, ["tell", "reply"])
          end

          def self.object_added(data)
            return unless data[:game_object].is_a? Player
            data[:game_object].subscribe(TellHandler.new(data[:game_object]))
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^tell\s+(\w+)\s+(.*)$/i
              action_tell({:target => $1, :message => $2 })
            when /^reply\s+(.*)$/i
              action_reply({:message => $1 })
            when /^help (tell)$/i
              action_help_tell({})
            when /^help (reply)$/i
              action_help_reply({})
            end
          end

          private
          def action_help_tell(event)
            @player.output <<'EOF'
Command: Tell
Syntax: TELL [player] [message]

All inhabitants of Aethyr have the ability to communicate privately with each other over long distances. This is done through the TELL command. Those who investigate these kinds of things claim there is some kind of latent telepathy in all of us. However, while no one knows for certain how it works, everyone knows it does.

Example:
TELL Justin Hey, how's it going?


See also: SAY, SAYTO, WHISPER, REPLY
EOF
          end

          def action_help_reply(event)
            @player.output <<'EOF'
Command: Reply
Syntax: REPLY [message]

Reply is a shortcut to send a tell to the last person who sent you a tell.

See also: TELL
EOF
          end

          #Tells someone something.
          def action_tell(event)
            target = $manager.find event[:target]
            unless target and target.is_a? Player
              @player.output "That person is not available."
              return
            end

            if target == @player
              @player.output "Talking to yourself?"
              return
            end

            phrase = event[:message]

            last_char = phrase[-1..-1]

            unless ["!", "?", "."].include? last_char
              phrase << "."
            end

            phrase[0,1] = phrase[0,1].upcase
            phrase = phrase.strip.gsub(/\s{2,}/, ' ')

            @player.output "You tell #{target.name}, <tell>\"#{phrase}\"</tell>"
            target.output "#{@player.name} tells you, <tell>\"#{phrase}\"</tell>"
            target.reply_to = @player.name
          end

          #Reply to a tell.
          def action_reply(event)
            unless @player.reply_to
              @player.output "There is no one to reply to."
              return
            end

            event[:target] = @player.reply_to

            action_tell(event)
          end
        end

        Aethyr::Extend::HandlerRegistry.register_handler(TellHandler)
      end
    end
  end
end
