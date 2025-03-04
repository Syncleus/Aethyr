require "aethyr/core/actions/commands/command_action"

module Aethyr
  module Core
    module Actions
      module Set
        class SetCommand < Aethyr::Extend::CommandAction
          def initialize(actor, **data)
            super(actor, **data)
          end

          def action
            

            room = $manager.get_object(@player.container)
            player = @player
            self[:setting].downcase!
            case self[:setting]
            when 'wordwrap'
              value = self[:value]
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
              value = self[:value]
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
            when "layout"
              case self[:value].downcase
              when "basic"
                player.layout = :basic
              when "partial"
                player.layout = :partial
              when "full"
                player.layout = :full
              when "wide"
                player.layout = :wide
              else
                player.output "#{value} is not a valid layout please set one of the following: basic, partial, full, wide."
              end
            else
              player.output "No such setting: #{self[:setting]}"
            end
          end

        end
      end
    end
  end
end
