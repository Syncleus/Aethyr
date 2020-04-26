require "aethyr/core/registry"
require "aethyr/core/commands/admin/admin_handler"

module Aethyr
  module Core
    module Commands
      module Acexit
        class AcexitHandler < Aethyr::Extend::AdminHandler

          def self.create_help_entries
            help_entries = []

            command = "acexit"
            see_also = nil
            syntax_formats = ["ACEXIT [DIRECTION] [EXIT_ROOM]"]
            aliases = nil
            content =  <<'EOF'
Sorry no help has been written for this command yet
EOF
            help_entries.push(Aethyr::Core::Help::HelpEntry.new(command, content: content, syntax_formats: syntax_formats, see_also: see_also, aliases: aliases))

            return help_entries
          end


          def initialize(player)
            super(player, ["acexit"], help_entries: AcexitHandler.create_help_entries)
          end

          def self.object_added(data)
            super(data, self)
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^acexit\s+(\w+)\s+(.*)$/i
              object = "exit"
              alt_names = [$1.strip]
              args = [$2.strip]
              acreate({:object => object, :alt_names => alt_names, :args => args})
            end
          end

          private
          def acreate(event)

            room = $manager.get_object(@player.container)
            player = @player
            class_name = event[:object]

            class_name[0,1] = class_name[0,1].capitalize

            if Object.const_defined? class_name
              klass = Object.const_get(class_name)
            else
              player.output "No such thing. Sorry."
              return
            end

            if not klass <= GameObject  or klass == Player
              player.output "You cannot create a #{klass.class}."
              return
            end

            vars = {}
            vars[:@name] = event[:name] if event[:name]
            vars[:@alt_names] = event[:alt_names] if event[:alt_names]
            vars[:@generic] = event[:generic] if event[:generic]
            args = event[:args]

            object = $manager.create_object(klass, room, nil, args, vars)

            if room
              event[:to_player] = "Frowning in concentration, you make vague motions with your hands. There is a small flash of light as #{object.name} appears."
              event[:to_other] = "Frowning in concentration, #{player.name} makes vague motions with #{player.pronoun(:possessive)} hands. There is a small flash of light as #{object.name} appears."
              room.out_event event
            end

            player.output "Created: #{object}"
            object
          end

        end
        Aethyr::Extend::HandlerRegistry.register_handler(AcexitHandler)
      end
    end
  end
end
