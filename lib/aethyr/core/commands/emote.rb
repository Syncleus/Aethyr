require "aethyr/core/registry"
require "aethyr/core/commands/emote_handler"

module Aethyr
  module Core
    module Commands
      module Emote
        class EmoteHandler < Aethyr::Extend::EmoteHandler
          def initialize(player)
            super(player, ["emote"])
          end

          def self.object_added(data)
            return unless data[:game_object].is_a? Player
            data[:game_object].subscribe(EmoteHandler.new(data[:game_object]))
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^emote\s+(.*)/i
              show = $1
              emote({:show => show})
            when /^help (emote)$/i
              action_help_emote({})
            end
          end

          private
          def action_help_emote(event)
            @player.output <<'EOF'
Please see help for emote instead.
EOF
          end


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
