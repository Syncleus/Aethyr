require "aethyr/core/actions/command_action"

module Aethyr
  module Core
    module Actions
      module Acreate
        class AcreateCommand < Aethyr::Core::Actions::CommandAction
          def initialize(actor, **data)
            super(actor, **data)
          end

          def action
            event = @data

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
      end
    end
  end
end
