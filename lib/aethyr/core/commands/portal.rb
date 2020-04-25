require "aethyr/core/registry"
require "aethyr/core/commands/command_handler"

module Aethyr
  module Core
    module Commands
      module Portal
        class PortalHandler < Aethyr::Extend::CommandHandler

          def self.create_help_entries
            help_entries = []

            command = "portal"
            see_also = nil
            syntax_formats = ["PORTAL [OBJECT] (ACTION|EXIT|ENTRANCE|PORTAL) [VALUE]"]
            aliases = nil
            content =  <<'EOF'
Sorry no help has been written for this command yet
EOF
            help_entries.push(Aethyr::Core::Help::HelpEntry.new(command, content: content, syntax_formats: syntax_formats, see_also: see_also, aliases: aliases))

            return help_entries
          end


          def initialize(player)
            super(player, ["portal"], PortalHandler.create_help_entries)
          end

          def self.object_added(data)
            super(data, self)
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^portal\s+(.*?)\s+(action|exit|entrance|portal)\s+(.*)$/i
              object = $1
              setting = $2.downcase
              value = $3.strip
              portal({:object => object, :setting => setting, :value => value})
            end
          end

          private
          def portal(event)

            room = $manager.get_object(@player.container)
            player = @player
            object = find_object(event[:object], event)
            if object.nil?
              player.output "Cannot find #{event[:object]}"
              return
            elsif not object.is_a? Portal
              player.output "That is not a portal."
              return
            end

            value = event[:value]

            case event[:setting]
            when "action"
              value.downcase!
              if value == "enter"
                object.info.delete :portal_action
                player.output "Set portal action to enter"
              elsif ["jump", "climb", "crawl"].include? value
                object.info.portal_action = value.downcase.to_sym
                player.output "Set portal action to #{value}"
              else
                player.output "#{value} is not a valid portal action."
              end
            when "exit"
              if value.downcase == "!nothing" or value.downcase == "nil"
                object.info.delete :exit_message
              else
                if value[-1,1] !~ /[!.?"']/
                  value << "."
                end
                object.info.exit_message = value
              end
              player.output "#{object.name} exit message set to: #{object.info.exit_message}"
            when "entrance"
              if value.downcase == "!nothing" or value.downcase == "nil"
                object.info.delete :entrance_message
              else
                if value[-1,1] !~ /[!.?"']/
                  value << "."
                end
                object.info.entrance_message = value
              end
              player.output "#{object.name} entrance message set to: #{object.info.entrance_message}"
            when "portal"
              if value.downcase == "!nothing" or value.downcase == "nil"
                object.info.delete :portal_message
              else
                if value[-1,1] !~ /[!.?"']/
                  value << "."
                end
                object.info.portal_message = value
              end
              player.output "#{object.name} portal message set to: #{object.info.portal_message}"
            else
              player.output "Valid options: action, exit, entrance, or portal."
            end
          end

        end
        Aethyr::Extend::HandlerRegistry.register_handler(PortalHandler)
      end
    end
  end
end
