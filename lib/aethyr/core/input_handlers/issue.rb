require "aethyr/core/actions/commands/issue"
require "aethyr/core/registry"
require "aethyr/core/input_handlers/command_handler"

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
            super(player, ["bug", "typo", "idea"], help_entries: IssueHandler.create_help_entries)
          end

          def self.object_added(data)
            super(data, self)
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^(bug|typo|idea)\s+(\d+)\s+(show|del|add|status)(\s+(.+))?$/i
              $manager.submit_action(Aethyr::Core::Actions::Issue::IssueCommand.new(@player,  :itype => $1.downcase.to_sym, :issue_id => $2, :option => $3.downcase, :value => $5 ))
            when /^(bug|typo|idea)\s+(\d+)/i
              $manager.submit_action(Aethyr::Core::Actions::Issue::IssueCommand.new(@player,  :itype => $1.downcase.to_sym, :option => "show", :issue_id => $2 ))
            when /^(bug|typo|idea)\s+(del|add|show|status)\s+(\d+)(\s+(.+))?/i
              $manager.submit_action(Aethyr::Core::Actions::Issue::IssueCommand.new(@player,  :itype => $1.downcase.to_sym, :option => $2.downcase, :issue_id => $3, :value => $5 ))
            when /^(bug|typo|idea)\s+(new|show|del|add|status|list)(\s+(.+))?$/i
              $manager.submit_action(Aethyr::Core::Actions::Issue::IssueCommand.new(@player,  :itype => $1.downcase.to_sym, :option => $2.downcase, :value => $4 ))
            when /^(bug|typo|idea)\s+(.*)$/i
              $manager.submit_action(Aethyr::Core::Actions::Issue::IssueCommand.new(@player,  :itype => $1.downcase.to_sym, :option => "new", :value => $2 ))
            end
          end

          private

        end

        Aethyr::Extend::HandlerRegistry.register_handler(IssueHandler)
      end
    end
  end
end
