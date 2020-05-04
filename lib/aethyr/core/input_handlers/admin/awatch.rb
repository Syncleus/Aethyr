require "aethyr/core/registry"
require "aethyr/core/actions/commands/admin/admin_handler"

module Aethyr
  module Core
    module Commands
      module Awatch
        class AwatchHandler < Aethyr::Extend::AdminHandler

          def self.create_help_entries
            help_entries = []

            command = "awatch"
            see_also = nil
            syntax_formats = ["AWATCH"]
            aliases = nil
            content =  <<'EOF'
Sorry no help has been written for this command yet
EOF
            help_entries.push(Aethyr::Core::Help::HelpEntry.new(command, content: content, syntax_formats: syntax_formats, see_also: see_also, aliases: aliases))

            return help_entries
          end


          def initialize(player)
            super(player, ["awatch"], help_entries: AwatchHandler.create_help_entries)
          end

          def self.object_added(data)
            super(data, self)
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^awatch\s+((start|stop)\s+)?(.*)$/i
              target = $3.downcase if $3
              command = $2.downcase if $2
              awatch({:target => target, :command => command})
            end
          end

          private
          def awatch(event)

            room = $manager.get_object(@player.container)
            player = @player
            object = find_object(event[:target], event)
            if object.nil?
              player.output "What mobile do you want to watch?"
              return
            elsif not object.is_a? Mobile
              player.output "You can only use this to watch mobiles."
              return
            end

            case event[:command]
            when "start"
              if object.info.redirect_output_to == player.goid
                player.output "You are already watching #{object.name}."
              else
                object.info.redirect_output_to = player.goid
                player.output "Watching #{object.name}."
                object.output "#{player.name} is watching you."
              end
            when "stop"
              if object.info.redirect_output_to != player.goid
                player.output "You are not watching #{object.name}."
              else
                object.info.redirect_output_to = nil
                player.output "No longer watching #{object.name}."
              end
            else
              if object.info.redirect_output_to != player.goid
                object.info.redirect_output_to = player.goid
                player.output "Watching #{object.name}."
                object.output "#{player.name} is watching you."
              else
                object.info.redirect_output_to = nil
                player.output "No longer watching #{object.name}."
              end
            end
          end

        end
        Aethyr::Extend::HandlerRegistry.register_handler(AwatchHandler)
      end
    end
  end
end
