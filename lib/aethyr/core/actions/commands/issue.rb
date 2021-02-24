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
            event = @data
            case event[:option]
            when "new"
              issue = Issues.add_issue event[:itype], player.name, event[:value]
              player.output "Thank you for submitting #{event[:itype]} ##{issue[:id]}."
            when "add"
              if not event[:issue_id]
                player.output "Please specify a #{event[:itype]} number."
              else
                denied = Issues.check_access event[:itype], event[:issue_id], player
                if denied
                  player.output denied
                else
                  player.output Issues.append_issue(event[:itype], event[:issue_id], player.name, event[:value])
                end
              end
            when "del"
              if not event[:issue_id]
                player.output "Please specify a #{event[:itype]} number."
              else
                denied = Issues.check_access event[:itype], event[:issue_id], player
                if denied
                  player.output denied
                else
                  player.output Issues.delete_issue(event[:itype], event[:issue_id])
                end
              end
            when "list"
              if player.admin
                list = Issues.list_issues event[:itype]
              else
                list = Issues.list_issues event[:itype], player.name
              end
              if list.empty?
                player.output "No #{event[:itype]}s to list."
              else
                player.output list
              end
            when "show"
              if not event[:issue_id]
                player.output "Please specify a #{event[:itype]} number."
              else
                denied = Issues.check_access event[:itype], event[:issue_id], player
                if denied
                  player.output denied
                else
                  player.output Issues.show_issue(event[:itype], event[:issue_id])
                end
              end
            when "status"
              if not player.admin
                player.output "Only administrators may change a #{event[:itype]}'s status."
              elsif not event[:issue_id]
                player.output "Please specify a #{event[:itype]} number."
              else
                player.output Issues.set_status(event[:itype], event[:issue_id], player.name, event[:value])
              end

            end
          end
        end
      end
    end
  end
end
