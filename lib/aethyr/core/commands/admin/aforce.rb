require "aethyr/core/registry"
require "aethyr/core/commands/admin/admin_handler"

module Aethyr
  module Core
    module Commands
      module Aforce
        class AforceHandler < Aethyr::Extend::AdminHandler

          def self.create_help_entries
            help_entries = []

            command = "aforce"
            see_also = nil
            syntax_formats = ["AFORCE [OBJECT] [ACTION]"]
            aliases = nil
            content =  <<'EOF'
Sorry no help has been written for this command yet
EOF
            help_entries.push(Aethyr::Core::Help::HelpEntry.new(command, content: content, syntax_formats: syntax_formats, see_also: see_also, aliases: aliases))

            return help_entries
          end


          def initialize(player)
            super(player, ["aforce"], AforceHandler.create_help_entries)
          end

          def self.object_added(data)
            super(data, self)
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^aforce\s+(.*?)\s+(.*)$/i
              target = $1
              command = $2
              aforce({:target => target, :command => command})
            end
          end

          private
          def aforce(event)

            room = $manager.get_object(@player.container)
            player = @player
            object = find_object(event[:target], event)
            if object.nil?
              player.output "Force who?"
              return
            elsif object.is_a? Mobile
              unless object.info.redirect_output_to == player.goid
                object.info.redirect_output_to = player.goid

                after 10 do
                  object.info.redirect_output_to = nil
                end
              end
            end

            player.add_event(CommandParser.parse(object, event[:command]))
          end

        end
        Aethyr::Extend::HandlerRegistry.register_handler(AforceHandler)
      end
    end
  end
end
