require "aethyr/core/registry"
require "aethyr/core/commands/command_handler"

module Aethyr
  module Core
    module Commands
      module Issue
        class IssueHandler < Aethyr::Extend::CommandHandler

          def self.create_help_entries
            help_entries = []

            command = "issue"
            see_also = nil
            syntax_formats = ["[BUG|IDEA|TYPO] [issue]", "[BUG|IDEA|TYPO] [id number]", "[BUG|IDEA|TYPO] LIST", "[BUG|IDEA|TYPO] STATUS [id_number] [status]", "[BUG|IDEA|TYPO] [SHOW|ADD|DEL] [id_number]"]
            aliases = ["bug", "typo", "idea"]
            content =  <<'EOF'
These commands allow players and administrators to report and manipulate feedback about the game. The commands are essentially identical, but should be used to report different things. For the rest of this description, BUG is used.

Note that players can only see and edit their own feedback, while adminsitrators will see them all.

BUG [issue] is used to make the initial report.
BUG LIST will list all reports.
BUG ADD can be used to append comments to a report.
BUG STATUS can be used to change the status of a report to a different value (administrators only).

Examples:
bug When I hit a dwarf with my axe, it doesn't do any damage.
bug list
bug 1
bug add 1 Actually, this only happens with battleaxes, not all axes.
EOF
            help_entries.push(Aethyr::Core::Help::HelpEntry.new(command, content: content, syntax_formats: syntax_formats, see_also: see_also, aliases: aliases))

            return help_entries
          end


          def initialize(player)
            super(player, ["bug", "typo", "idea"], IssueHandler.create_help_entries)
          end

          def self.object_added(data)
            super(data, self)
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^(bug|typo|idea)\s+(\d+)\s+(show|del|add|status)(\s+(.+))?$/i
              action({ :itype => $1.downcase.to_sym, :issue_id => $2, :option => $3.downcase, :value => $5 })
            when /^(bug|typo|idea)\s+(\d+)/i
              action({ :itype => $1.downcase.to_sym, :option => "show", :issue_id => $2 })
            when /^(bug|typo|idea)\s+(del|add|show|status)\s+(\d+)(\s+(.+))?/i
              action({ :itype => $1.downcase.to_sym, :option => $2.downcase, :issue_id => $3, :value => $5 })
            when /^(bug|typo|idea)\s+(new|show|del|add|status|list)(\s+(.+))?$/i
              action({ :itype => $1.downcase.to_sym, :option => $2.downcase, :value => $4 })
            when /^(bug|typo|idea)\s+(.*)$/i
              action({ :itype => $1.downcase.to_sym, :option => "new", :value => $2 })
            end
          end

          private
          def action(event)
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

        Aethyr::Extend::HandlerRegistry.register_handler(IssueHandler)
      end
    end
  end
end
