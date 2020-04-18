require "aethyr/core/registry"
require "aethyr/core/commands/command_handler"

module Aethyr
  module Core
    module Commands
      module Set
        class SetHandler < Aethyr::Extend::CommandHandler
          def initialize(player)
            super(player, ["set"])
          end

          def self.object_added(data)
            return unless data[:game_object].is_a? Player
            data[:game_object].subscribe(SetHandler.new(data[:game_object]))
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^set\s+colors?\s+(on|off|default)$/i
              option = $1
              setcolor({:option => option})
            when /^set\s+colors?.*/i
              showcolors({})
            when /^set\s+(\w+)\s*(.*)$/i
              setting = $1.strip
              value = $2.strip if $2
              set({:setting => setting, :value => value})
            when /^set\s+colors?\s+(\w+)\s+(.+)$/i
              option = $1
              color = $2
              setcolor({:option => option, :color => color})
            when /^set\s+password$/i
              setpassword({})
            when /^help (set)$/i
              action_help_set({})
            end
          end

          private
          def action_help_set(event)
            @player.output <<'EOF'
Syntax: SET <option> [value]

There are several settings available to you. To see them all, simply use SET.
To see the values available for a certain setting, use SET <option> without a value.

Example:

To see your color settings, use

SET COLOR

To turn off word wrap, use

SET WORDWRAP OFF

See also: WORDWRAP, PAGELENGTH, DESCRIPTION, COLORS

EOF
          end


          def setcolor(event)

            room = $manager.get_object(@player.container)
            player = @player
            if event[:option] == "off"
              player.io.use_color = false
              player.output "Colors disabled."
            elsif event[:option] == "on"
              player.io.use_color = true
              player.output "Colors enabled."
            elsif event[:option] == "default"
              player.io.to_default
              player.output "Colors set to defaults."
            else
              player.output player.io.set_color(event[:option], event[:color])
            end
          end

          def showcolors(event)

            room = $manager.get_object(@player.container)
            player = @player
            player.output player.io.display.show_color_config
          end

          def set(event)

            room = $manager.get_object(@player.container)
            player = @player
            event[:setting].downcase!
            case event[:setting]
            when 'wordwrap'
              value = event[:value]
              if player.word_wrap.nil?
                player.output("Word wrap is currently off.", true)
              else
                player.output("Word wrap currently set to #{player.word_wrap}.", true)
              end

              if value.nil?
                player.output "Please specify 'off' or a value between 10 - 200."
                return
              elsif value.downcase == 'off'
                player.word_wrap = nil
                player.output "Word wrap is now disabled."
                return
              else
                value = value.to_i
                if value > 200 or value < 10
                  player.output "Please use a value between 10 - 200."
                  return
                else
                  player.word_wrap = value
                  player.output "Word wrap is now set to: #{value} characters."
                  return
                end
              end
            when 'pagelength', "page_length"
              value = event[:value]
              if player.page_height.nil?
                player.output("Pagination is currently off.", true)
              else
                player.output("Page length is currently set to #{player.page_height}.", true)
              end

              if value.nil?
                player.output "Please specify 'off' or a value between 1 - 200."
                return
              elsif value.downcase == 'off'
                player.page_height = nil
                player.output "Output will no longer be paginated."
                return
              else
                value = value.to_i
                if value > 200 or value < 1
                  player.output "Please use a value between 1 - 200."
                  return
                else
                  player.page_height = value
                  player.output "Page length is now set to: #{value} lines."
                  return
                end

              end
            when "desc", "description"
              player.editor(player.instance_variable_get(:@long_desc) || [], 10) do |data|
                unless data.nil?
                  player.long_desc = data.strip
                end
                player.output("Set description to:\r\n#{player.long_desc}")
              end
            else
              player.output "No such setting: #{event[:setting]}"
            end
          end

          def setpassword(event)

            room = $manager.get_object(@player.container)
            player = @player
            if event[:new_password]
              if event[:new_password] !~ /^\w{6,20}$/
                player.output "Please only use letters and numbers. Password should be between 6 and 20 characters long."
                return
              else
                $manager.set_password(player, event[:new_password])
                player.output "Your password has been changed."
              end
            else
              player.output "Please enter your current password:", true
              player.io.echo_off
              player.expect do |password|
                if $manager.check_password(player.name, password)
                  player.output "Please enter your new password:", true
                  player.io.echo_off
                  player.expect do |password|
                    player.io.echo_on
                    event[:new_password] = password
                    Settings.setpassword(event, player, room)
                  end
                else
                  player.output "Sorry, that password is invalid."
                  player.io.echo_on
                end

              end
            end
          end

        end
        Aethyr::Extend::HandlerRegistry.register_handler(SetHandler)
      end
    end
  end
end
