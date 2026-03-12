Feature: News board trait
  The News trait provides newsboard functionality for game objects,
  including posting, reading, replying, listing, and deleting messages.

  Background:
    Given a News board test object is set up

  # ---- save / retrieve ----

  Scenario: Saving and retrieving a post
    When a News post is saved with title "Hello World" by "Alice"
    Then the News post count should be 1
    And retrieving News post 1 should have title "Hello World"
    And retrieving News post 1 should have author "Alice"

  Scenario: Saving multiple posts increments the post count
    When a News post is saved with title "First" by "Alice"
    And a News post is saved with title "Second" by "Bob"
    Then the News post count should be 2
    And retrieving News post 2 should have title "Second"

  Scenario: Retrieving a non-existent News post returns nil
    Then retrieving News post 999 should return nil

  # ---- show_post ----

  Scenario: Showing a post without a reply
    Given a News post exists with title "Standalone" by "Carol" and no reply
    When the News post 1 is shown
    Then the News show output should contain "Standalone"
    And the News show output should contain "Carol"
    And the News show output should contain the board name

  Scenario: Showing a post that is a reply to another post
    Given a News post exists with title "Original" by "Dave" and no reply
    And a News reply exists with title "Response" by "Eve" replying to post 1
    When the News post 2 is shown
    Then the News show output should contain "Response"
    And the News show output should contain "Re  :"
    And the News show output should contain "Original"

  Scenario: Showing a post that replies to a deleted parent
    Given a News post exists with title "Original" by "Frank" and no reply
    And a News reply exists with title "Orphan Reply" by "Grace" replying to post 1
    And News post "1" is deleted
    When the News post 2 is shown
    Then the News show output should contain "Orphan Reply"
    And the News show output should not contain "Re  :"

  Scenario: Showing a post by numeric ID exercises the non-Hash path
    Given a News post exists with title "ById" by "Hank" and no reply
    When show_post is called with a numeric News post ID 1
    Then the News show output from ID should contain "ById"

  Scenario: Showing a post with custom word wrap
    Given a News post exists with title "Wrapped" by "Iris" and no reply
    When the News post 1 is shown with word wrap 40
    Then the News show output should contain a separator of length 40

  Scenario: Showing a post that has replies listed
    Given a News post exists with title "Parent" by "Jack" and no reply
    And a News reply exists with title "Child Reply" by "Kate" replying to post 1
    When the News post 1 is shown
    Then the News show output should contain "Replies:"
    And the News show output should contain "Child Reply"

  # ---- list_latest ----

  Scenario: Listing latest on an empty board
    When the News latest posts are listed
    Then the News latest output should contain "No posts to show."

  Scenario: Listing latest posts with content
    Given a News post exists with title "Alpha" by "Leo" and no reply
    And a News post exists with title "Beta" by "Mia" and no reply
    When the News latest posts are listed
    Then the News latest output should contain "Alpha"
    And the News latest output should contain "Beta"
    And the News latest output should contain the board name header

  Scenario: Listing latest posts with a reply chain shows indentation
    Given a News post exists with title "Root" by "Ned" and no reply
    And a News reply exists with title "Reply1" by "Olive" replying to post 1
    When the News latest posts are listed
    Then the News latest output should contain "Root"
    And the News latest output should contain "Reply1"

  Scenario: Listing latest with nil limit uses all posts
    Given a News post exists with title "Post A" by "Pat" and no reply
    And a News post exists with title "Post B" by "Quinn" and no reply
    When the News latest posts are listed with nil limit
    Then the News latest output should contain "Post A"
    And the News latest output should contain "Post B"

  Scenario: Listing latest with an offset beyond available posts
    Given a News post exists with title "Only Post" by "Rose" and no reply
    When the News latest posts are listed with offset 100
    Then the News latest output should contain "No posts to show."

  Scenario: Listing latest shows a "more" indicator when posts are truncated
    Given 3 sequential News posts exist without replies
    When the News latest posts are listed with offset 1 and limit 1
    Then the News latest output should contain "--NEWS"
    And the News latest output should contain "for more--"

  Scenario: Listing latest with a complex reply tree
    Given a News post exists with title "TreeRoot" by "Sam" and no reply
    And a News reply exists with title "Branch1" by "Tina" replying to post 1
    And a News reply exists with title "Branch2" by "Uma" replying to post 1
    When the News latest posts are listed
    Then the News latest output should contain "TreeRoot"
    And the News latest output should contain "Branch1"
    And the News latest output should contain "Branch2"

  Scenario: Listing latest with deep nested replies exercises insert_parent
    Given a News post exists with title "Deep1" by "Vera" and no reply
    And a News reply exists with title "Deep2" by "Walt" replying to post 1
    And a News reply exists with title "Deep3" by "Xena" replying to post 2
    When the News latest posts are listed
    Then the News latest output should contain "Deep1"
    And the News latest output should contain "Deep2"
    And the News latest output should contain "Deep3"

  # ---- list_replies ----

  Scenario: Listing replies for a post with no replies
    Given a News post exists with title "Lonely" by "Yuki" and no reply
    Then listing News replies for post 1 should return nil

  Scenario: Listing replies for a post with replies
    Given a News post exists with title "Popular" by "Zack" and no reply
    And a News reply exists with title "Re: Popular" by "Amy" replying to post 1
    Then listing News replies for post 1 should contain "Replies:"
    And listing News replies for post 1 should contain "Re: Popular"

  # ---- delete ----

  Scenario: Deleting a News post removes it from the board
    Given a News post exists with title "ToDelete" by "Ben" and no reply
    When News post "1" is deleted
    Then retrieving News post 1 should return nil

  # ---- announce_new ----

  Scenario: Announce new returns the configured announcement
    Then the News board announcement should be "Breaking news on the board!"
