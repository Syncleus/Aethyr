require "aethyr/core/registry"
require "aethyr/core/commands/admin/admin_handler"

module Aethyr
  module Core
    module Commands
      module Acprop
        class AcpropHandler < Aethyr::Extend::AdminHandler
          def initialize(player)
            super(player, ["acprop"])
          end

          def self.object_added(data)
            return unless data[:game_object].is_a? Player
            data[:game_object].subscribe(AcpropHandler.new(data[:game_object]))
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^acprop\s+(.*)$/i
              object = "prop"
              generic = $1
              acreate({:object => object, :generic => generic})
            when /^help (acprop)$/i
              action_help_acprop({})
            end
          end

          private
          def action_help_acprop(event)
            @player.output <<'EOF'
Sorry no help has been written for this command yet
EOF
          end


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
        Aethyr::Extend::HandlerRegistry.register_handler(AcpropHandler)
      end
    end
  end
end
