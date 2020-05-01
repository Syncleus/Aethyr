require "aethyr/core/registry"
require "aethyr/core/actions/commands/command_handler"

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
              latest_news({})
            when /^news\s+(read\s+)?(\d+)$/i
              post_id = $2
              read_post({:post_id => post_id})
            when /^news\s+reply(\s+to\s+)?\s+(\d+)$/i
              reply_to = $2
              write_post({:reply_to => reply_to})
            when /^news\s+unread/i
              list_unread({})
            when /^news\s+last\s+(\d+)/i
              limit = $1.to_i
              latest_news({:limit => limit})
            when /^news\s+delete\s+(\d+)/i
              post_id = $1
              delete_post({:post_id => post_id})
            when /^news\s+write$/i
              write_post({})
            when /^news\s+all/i
              all({})
            end
          end

          private
          def latest_news(event)

            room = $manager.get_object(@player.container)
            player = @player
            board = find_board(event, room)

            if board.nil?
              player.output "There do not seem to be any postings here."
              return
            end

            if not board.is_a? Newsboard
              log board.class
            end

            offset = event[:offset] || 0
            wordwrap = player.word_wrap || 100
            limit = event[:limit] || player.page_height

            player.output board.list_latest(wordwrap, offset, limit)
          end

          def read_post(event)

            room = $manager.get_object(@player.container)
            player = @player
            board = find_board(event, room)

            if board.nil?
              player.output "There do not seem to be any postings here."
              return
            end

            post = board.get_post event[:post_id]
            if post.nil?
              player.output "No such posting here."
              return
            end

            if player.info.boards.nil?
              player.info.boards = {}
            end

            player.info.boards[board.goid] = event[:post_id].to_i

            player.output board.show_post(post, player.word_wrap || 80)
          end

          def write_post(event)

            room = $manager.get_object(@player.container)
            player = @player
            board = find_board(event, room)

            if board.nil?
              player.output "There do not seem to be any postings here."
              return
            end

            player.output("What is the subject of this post?", true)

            player.expect do |subj|
              player.editor do |message|
                unless message.nil?
                  post_id = board.save_post(player, subj, event[:reply_to], message)
                  player.output "You have written post ##{post_id}."
                  if board.announce_new
                    area = $manager.get_object(board.container).area
                    area.output board.announce_new
                  end
                end
              end
            end
          end

          def list_unread(event)

            room = $manager.get_object(@player.container)
            player = @player
            board = find_board(event, room)

            if board.nil?
              player.output "There do not seem to be any postings here."
              return
            end

            if player.info.boards.nil?
              player.info.boards = {}
            end

            player.output board.list_since(player.info.boards[board.goid], player.word_wrap)
          end

          def delete_post(event)

            room = $manager.get_object(@player.container)
            player = @player




            board = find_board(event, room)

            if board.nil?
              player.output "What newsboard are you talking about?"
              return
            end

            post = board.get_post event[:post_id]

            if post.nil?
              player.output "No such post."
            elsif post[:author] != player.name
              player.output "You can only delete your own posts."
            else
              board.delete_post event[:post_id]
              player.output "Deleted post ##{event[:post_id]}"
            end
          end

          def all(event)

            room = $manager.get_object(@player.container)
            player = @player
            board = find_board(event, room)

            if board.nil?
              player.output "There do not seem to be any postings here."
              return
            end

            wordwrap = player.word_wrap || 100

            player.output board.list_latest(wordwrap, 0, nil)
          end

        end
        Aethyr::Extend::HandlerRegistry.register_handler(NewsHandler)
      end
    end
  end
end
