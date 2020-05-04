require "aethyr/core/registry"
require "aethyr/core/actions/commands/admin/admin_handler"

module Aethyr
  module Core
    module Commands
      module Acportal
        class AcportalHandler < Aethyr::Extend::AdminHandler

          def self.create_help_entries
            help_entries = []

            command = "acportal"
            see_also = nil
            syntax_formats = ["ACPORTAL"]
            aliases = nil
            content =  <<'EOF'
Sorry no help has been written for this command yet
EOF
            help_entries.push(Aethyr::Core::Help::HelpEntry.new(command, content: content, syntax_formats: syntax_formats, see_also: see_also, aliases: aliases))

            return help_entries
          end


          def initialize(player)
            super(player, ["acportal"], help_entries: AcportalHandler.create_help_entries)
          end

          def self.object_added(data)
            super(data, self)
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^acportal(\s+(jump|climb|crawl|enter))?(\s+(.*))?$/i
              object = "portal"
              alt_names = []
              portal_action = $2
              args = [$4]
              acportal({:object => object, :alt_names => alt_names, :portal_action => portal_action, :args => args})
            end
          end

          private
          def acportal(event)

            room = $manager.get_object(@player.container)
            player = @player
            object = Admin.acreate(event, player, room)
            if event[:portal_action] and event[:portal_action].downcase != "enter"
              object.info.portal_action = event[:portal_action].downcase.to_sym
            end
          end

        end
        Aethyr::Extend::HandlerRegistry.register_handler(AcportalHandler)
      end
    end
  end
end
