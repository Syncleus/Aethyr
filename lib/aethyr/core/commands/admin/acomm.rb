require "aethyr/core/registry"
require "aethyr/core/commands/admin/admin_handler"

module Aethyr
  module Core
    module Commands
      module Acomm
        class AcommHandler < Aethyr::Extend::AdminHandler

          def self.create_help_entries
            help_entries = []

            command = "acomm"
            see_also = nil
            syntax_formats = ["ACOMMENT [OBJECT] [COMMENT]"]
            aliases = nil
            content =  <<'EOF'
Sorry no help has been written for this command yet
EOF
            help_entries.push(Aethyr::Core::Help::HelpEntry.new(command, content: content, syntax_formats: syntax_formats, see_also: see_also, aliases: aliases))

            return help_entries
          end


          def initialize(player)
            super(player, ["acomm"], AcommHandler.create_help_entries)
          end

          def self.object_added(data)
            super(data, self)
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^(acomm|acomment)\s+(.*?)\s+(.*)$/i
              target = $2
              comment = $3
              acomment({:target => target, :comment => comment})
            end
          end

          private
          def acomment(event)

            room = $manager.get_object(@player.container)
            player = @player
            object = find_object(event[:target], event)
            if object.nil?
              player.output "Cannot find:#{event[:target]}"
              return
            end

            object.comment = event[:comment]
            player.output "Added comment: '#{event[:comment]}'\nto#{object}"
          end

        end
        Aethyr::Extend::HandlerRegistry.register_handler(AcommHandler)
      end
    end
  end
end
