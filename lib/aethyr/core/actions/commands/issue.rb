require "aethyr/core/actions/commands/command_action"

module Aethyr
  module Core
    module Actions
      module Issue
        class IssueCommand < Aethyr::Extend::CommandAction
          def initialize(actor, **data)
            super(actor, **data)
          end

          def action

            case self[:option]
            when "new"
              issue = Issues.add_issue self[:itype], player.name, self[:value]
              player.output "Thank you for submitting #{self[:itype]} ##{issue[:id]}."
            when "add"
              if not self[:issue_id]
                player.output "Please specify a #{self[:itype]} number."
              else
                denied = Issues.check_access self[:itype], self[:issue_id], player
                if denied
                  player.output denied
                else
                  player.output Issues.append_issue(self[:itype], self[:issue_id], player.name, self[:value])
                end
              end
            when "del"
              if not self[:issue_id]
                player.output "Please specify a #{self[:itype]} number."
              else
                denied = Issues.check_access self[:itype], self[:issue_id], player
                if denied
                  player.output denied
                else
                  player.output Issues.delete_issue(self[:itype], self[:issue_id])
                end
              end
            when "list"
              if player.admin
                list = Issues.list_issues self[:itype]
              else
                list = Issues.list_issues self[:itype], player.name
              end
              if list.empty?
                player.output "No #{self[:itype]}s to list."
              else
                player.output list
              end
            when "show"
              if not self[:issue_id]
                player.output "Please specify a #{self[:itype]} number."
              else
                denied = Issues.check_access self[:itype], self[:issue_id], player
                if denied
                  player.output denied
                else
                  player.output Issues.show_issue(self[:itype], self[:issue_id])
                end
              end
            when "status"
              if not player.admin
                player.output "Only administrators may change a #{self[:itype]}'s status."
              elsif not self[:issue_id]
                player.output "Please specify a #{self[:itype]} number."
              else
                player.output Issues.set_status(self[:itype], self[:issue_id], player.name, self[:value])
              end

            end
          end
        end
      end
    end
  end
end
