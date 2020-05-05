require "aethyr/core/actions/commands/all"
require "aethyr/core/actions/commands/delete_post"
require "aethyr/core/actions/commands/list_unread"
require "aethyr/core/actions/commands/write_post"
require "aethyr/core/actions/commands/read_post"
require "aethyr/core/actions/commands/latest_news"
require "aethyr/core/registry"
require "aethyr/core/input_handlers/command_handler"

module Aethyr
  module Core
    module Commands
      module News
        class NewsHandler < Aethyr::Extend::CommandHandler

          def self.create_help_entries
            help_entries = []

            command = "news"
            see_also = nil
            syntax_formats = ["NEWS"]
            aliases = nil
            content =  <<'EOF'
NEWS

Scattered throughout Aethyr are objects on which one can post notes or read notes left by others. The appearance of these objects may vary from ledgers to large bulletin boards, but they all work the same way.

The news system is currently still being tinkered on, but here is what works currently:

-Reading posts

Lists the latest news. How many posts it lists is dependent on your pagelength.

Specify how many of the latest posts to show.

Lists all the news postings. Might be really long.

Shows the specified post.

-Writing posts

First enter a subject for your post, then you will be taken to the editor to write the body of the post. If you decide not to write the post after all, then simply exit the editor without saving.

Write a reply to an existing post.

-Deleting posts

For testing purposes only, you may delete your own posts. This is so you don't feel guilty about posting a bunch of nonsense to try things out.

Note that this command isn't really well-supported, so it may cause some odd things to happen if there are replies to deleted posts.

EOF
            help_entries.push(Aethyr::Core::Help::HelpEntry.new(command, content: content, syntax_formats: syntax_formats, see_also: see_also, aliases: aliases))

            return help_entries
          end


          def initialize(player)
            super(player, ["news"], help_entries: NewsHandler.create_help_entries)
          end

          def self.object_added(data)
            super(data, self)
          end

          def player_input(data)
            super(data)
            case data[:input]
            when "news"
              $manager.submit_action(Aethyr::Core::Actions::LatestNews::LatestNewsCommand.new(@player, {}))
            when /^news\s+(read\s+)?(\d+)$/i
              post_id = $2
              $manager.submit_action(Aethyr::Core::Actions::ReadPost::ReadPostCommand.new(@player, {:post_id => post_id}))
            when /^news\s+reply(\s+to\s+)?\s+(\d+)$/i
              reply_to = $2
              $manager.submit_action(Aethyr::Core::Actions::WritePost::WritePostCommand.new(@player, {:reply_to => reply_to}))
            when /^news\s+unread/i
              $manager.submit_action(Aethyr::Core::Actions::ListUnread::ListUnreadCommand.new(@player, {}))
            when /^news\s+last\s+(\d+)/i
              limit = $1.to_i
              $manager.submit_action(Aethyr::Core::Actions::LatestNews::LatestNewsCommand.new(@player, {:limit => limit}))
            when /^news\s+delete\s+(\d+)/i
              post_id = $1
              $manager.submit_action(Aethyr::Core::Actions::DeletePost::DeletePostCommand.new(@player, {:post_id => post_id}))
            when /^news\s+write$/i
              $manager.submit_action(Aethyr::Core::Actions::WritePost::WritePostCommand.new(@player, {}))
            when /^news\s+all/i
              $manager.submit_action(Aethyr::Core::Actions::All::AllCommand.new(@player, {}))
            end
          end

          private






        end
        Aethyr::Extend::HandlerRegistry.register_handler(NewsHandler)
      end
    end
  end
end
