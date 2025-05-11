require 'aethyr/core/objects/game_object'
require 'aethyr/core/objects/traits/news'

module Aethyr
  module Extensions
    module Objects
      #Newsboards for posting news.
      #
      #===Info
      # board_name (String)
      # announce_new (String)
      class Newsboard < Aethyr::Core::Objects::GameObject
        include News

        def initialize(*args)
          super
          @name = 'newsboard'
          @generic = 'newsboard'
          @alt_names = ['board', 'bulletin board', 'notice board', 'messageboard']
          @movable = false
          @info.board_name = "A Nice Board"
          @info.announce_new = "An excited voice shouts, \"Someone wrote a new post!\""
        end
      end
    end
  end
end
