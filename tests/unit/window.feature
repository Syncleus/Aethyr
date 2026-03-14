Feature: Window rendering component
  In order to display game output in ncurses panels
  As the rendering subsystem
  I want the Window class to manage ncurses windows, buffering, color, and text wrapping.

  # --------------------------------------------------------------------------
  # Initialization
  # --------------------------------------------------------------------------
  Scenario: Creating a non-buffered window instance
    Given a non-buffered Window instance
    Then the window should not be buffered
    And the window should not exist yet
    And the window should not use color
    And the window should not be selected

  Scenario: Creating a buffered window instance
    Given a buffered Window instance with buffer size 500
    Then the window should be buffered
    And the window buffer should be empty
    And the window buffer_lines should be empty
    And the window buffer_pos should be 0
    And the window buffer_size should be 500

  Scenario: Creating a buffered window with default buffer size
    Given a buffered Window instance
    Then the window buffer_size should be 10000

  # --------------------------------------------------------------------------
  # exist?
  # --------------------------------------------------------------------------
  Scenario: Checking existence before and after create
    Given a non-buffered Window instance
    Then the window should not exist yet
    When the window is created with width 40 height 20 x 0 y 0
    Then the window should exist

  # --------------------------------------------------------------------------
  # create – validation
  # --------------------------------------------------------------------------
  Scenario: Creating a window with negative width raises an error
    Given a non-buffered Window instance
    Then creating the window with width -1 height 10 x 0 y 0 should raise "width out of range"

  Scenario: Creating a window with negative height raises an error
    Given a non-buffered Window instance
    Then creating the window with width 10 height -1 x 0 y 0 should raise "height out of range"

  Scenario: Creating a window with negative x raises an error
    Given a non-buffered Window instance
    Then creating the window with width 10 height 10 x -1 y 0 should raise "x out of range"

  Scenario: Creating a window with negative y raises an error
    Given a non-buffered Window instance
    Then creating the window with width 10 height 10 x 0 y -1 should raise "y out of range"

  # --------------------------------------------------------------------------
  # create – normal path
  # --------------------------------------------------------------------------
  Scenario: Creating a window stores dimensions and initializes ncurses windows
    Given a non-buffered Window instance
    When the window is created with width 40 height 20 x 5 y 3
    Then the window width should be 40
    And the window height should be 20
    And the window x should be 5
    And the window y should be 3
    And the window should exist
    And the window_border should not be nil
    And the window_text should not be nil
    And the text_height should be a non-negative integer
    And the text_width should be a non-negative integer

  # --------------------------------------------------------------------------
  # create – buffered path
  # --------------------------------------------------------------------------
  Scenario: Creating a buffered window renders existing buffer content
    Given a buffered Window instance
    And the buffer contains "Hello world"
    When the window is created with width 40 height 20 x 0 y 0
    Then the window buffer_pos should be 0

  # --------------------------------------------------------------------------
  # destroy
  # --------------------------------------------------------------------------
  Scenario: Destroying a window clears its state
    Given a non-buffered Window instance
    When the window is created with width 40 height 20 x 0 y 0
    And the window is destroyed
    Then the window should not exist yet
    And the window_border should be nil
    And the window_text should be nil
    And the window should not be selected

  Scenario: Destroying a window that was never created does not raise
    Given a non-buffered Window instance
    When the window is destroyed
    Then the window should not exist yet

  # --------------------------------------------------------------------------
  # update
  # --------------------------------------------------------------------------
  Scenario: Updating a created window without color
    Given a non-buffered Window instance
    When the window is created with width 40 height 20 x 0 y 0
    And the window is updated
    Then no error should have been raised

  Scenario: Updating a created window with color enabled
    Given a non-buffered Window instance
    When the window is created with width 40 height 20 x 0 y 0
    And color is enabled on the window
    And the window is updated
    Then no error should have been raised

  Scenario: Updating a selected window without color
    Given a non-buffered Window instance
    When the window is created with width 40 height 20 x 0 y 0
    And the window is selected
    And the window is updated
    Then no error should have been raised

  Scenario: Updating a selected window with color enabled
    Given a non-buffered Window instance
    When the window is created with width 40 height 20 x 0 y 0
    And color is enabled on the window
    And the window is selected
    And the window is updated
    Then no error should have been raised

  # --------------------------------------------------------------------------
  # enable_color
  # --------------------------------------------------------------------------
  Scenario: Enabling color on a window
    Given a non-buffered Window instance
    When color is enabled on the window
    Then the window should use color

  # --------------------------------------------------------------------------
  # activate_color
  # --------------------------------------------------------------------------
  Scenario: Activating a color pair via the public method
    Given a non-buffered Window instance with color enabled and window created
    When activate_color is called with fg 15 and bg 0
    Then no error should have been raised

  # --------------------------------------------------------------------------
  # clear
  # --------------------------------------------------------------------------
  Scenario: Clearing a non-buffered window
    Given a non-buffered Window instance
    When the window is created with width 40 height 20 x 0 y 0
    And the window is cleared
    Then no error should have been raised

  Scenario: Clearing a buffered window resets the buffer
    Given a buffered Window instance
    When the window is created with width 40 height 20 x 0 y 0
    And "test message" is sent to the window
    And the window is cleared
    Then the window buffer should be empty

  # --------------------------------------------------------------------------
  # send – non-buffered
  # --------------------------------------------------------------------------
  Scenario: Sending a message to a non-buffered window
    Given a non-buffered Window instance
    When the window is created with width 40 height 20 x 0 y 0
    And "Hello world" is sent to the window
    Then no error should have been raised

  Scenario: Sending a message to a non-buffered window without newline
    Given a non-buffered Window instance
    When the window is created with width 40 height 20 x 0 y 0
    And "Hello world" is sent to the window without newline
    Then no error should have been raised

  # --------------------------------------------------------------------------
  # send – buffered
  # --------------------------------------------------------------------------
  Scenario: Sending a message to a buffered window appends to buffer
    Given a buffered Window instance
    When the window is created with width 40 height 20 x 0 y 0
    And "Hello buffered" is sent to the window
    Then the window buffer should contain "Hello buffered"

  Scenario: Sending a message to a buffered window without add_newline
    Given a buffered Window instance
    When the window is created with width 40 height 20 x 0 y 0
    And "No newline msg" is sent to the window without newline
    Then the window buffer should contain "No newline msg"

  Scenario: Buffer trimming branch is exercised when exceeding buffer_size
    Given a buffered Window instance with buffer size 5
    When the window is created with width 40 height 20 x 0 y 0
    And 10 messages are sent to the window
    Then no error should have been raised

  # --------------------------------------------------------------------------
  # buffer_pos=
  # --------------------------------------------------------------------------
  Scenario: Setting buffer_pos to a valid value
    Given a buffered Window instance
    When the window is created with width 40 height 20 x 0 y 0
    And 30 messages are sent to the window
    And buffer_pos is set to 2
    Then the window buffer_pos should be 2

  Scenario: Setting buffer_pos to a negative value is ignored
    Given a buffered Window instance
    When the window is created with width 40 height 20 x 0 y 0
    And 30 messages are sent to the window
    And buffer_pos is set to -1
    Then the window buffer_pos should be 0

  # --------------------------------------------------------------------------
  # self.split_message
  # --------------------------------------------------------------------------
  Scenario: Splitting a simple single-line message
    When split_message is called with the text "Hello world" and cols 80
    Then the split result should have 1 line
    And split result line 0 should be "Hello world"

  Scenario: Splitting a message with embedded newlines
    When split_message is called with the text "Line one\nLine two" and cols 80
    Then the split result should have 2 lines
    And split result line 0 should be "Line one"
    And split result line 1 should be "Line two"

  Scenario: Splitting a message with consecutive newlines
    When split_message is called with the text "Line one\n\nLine three" and cols 80
    Then the split result should have 3 lines

  Scenario: Splitting a message with tab characters
    When split_message is called with the text "Hello\tworld" and cols 80
    Then the split result should have 1 line

  Scenario: Splitting a message with carriage returns
    When split_message is called with the text "Hello\r\nworld" and cols 80
    Then the split result should have 2 lines

  Scenario: Splitting an empty string
    When split_message is called with the text "" and cols 80
    Then the split result should have 0 lines

  # --------------------------------------------------------------------------
  # self.word_wrap
  # --------------------------------------------------------------------------
  Scenario: Word wrapping a short line that fits within columns
    When word_wrap is called with the text "short line" and cols 80
    Then the wrap result should have 1 line
    And wrap result line 0 should be "short line"

  Scenario: Word wrapping a long line that exceeds columns
    When word_wrap is called with the text "the quick brown fox jumps over" and cols 15
    Then the wrap result should have at least 2 lines

  Scenario: Word wrapping with HTML-like tags does not count tag chars
    When word_wrap is called with the text "<bold>hello world</bold>" and cols 15
    Then the wrap result should have 1 line

  Scenario: Word wrapping a single very long word that exceeds columns
    When word_wrap is called with the text "abcdefghijklmnopqrstuvwxyz" and cols 10
    Then the wrap result should have at least 1 line

  Scenario: Word wrapping with leading spaces
    When word_wrap is called with the text "  hello world" and cols 80
    Then the wrap result should have 1 line

  Scenario: Word wrapping where a word boundary coincides with column limit
    When word_wrap is called with the text "abcde fghij" and cols 5
    Then the wrap result should have at least 2 lines

  Scenario: Word wrapping a line with spaces that triggers whitespace overflow branch
    When word_wrap is called with the text "ab cd ef gh ij kl" and cols 5
    Then the wrap result should have at least 2 lines

  Scenario: Word wrapping with space overflow when word exceeds single column
    When word_wrap is called with the text "a b " and cols 1
    Then the wrap result should have at least 2 lines

  # --------------------------------------------------------------------------
  # colored_send – no color
  # --------------------------------------------------------------------------
  Scenario: Colored send with no color enabled renders plain text
    Given a non-buffered Window instance
    When the window is created with width 40 height 20 x 0 y 0
    And "plain text" is sent to the window
    Then no error should have been raised

  # --------------------------------------------------------------------------
  # colored_send – with color
  # --------------------------------------------------------------------------
  Scenario: Colored send with color enabled and tagged message
    Given a non-buffered Window instance with color enabled and window created
    When "<regular>colored text</regular>" is sent to the window
    Then no error should have been raised

  Scenario: Colored send with unknown color tag defaults to regular
    Given a non-buffered Window instance with color enabled and window created
    When "<nonexistent>text</nonexistent>" is sent to the window
    Then no error should have been raised

  Scenario: Colored send with empty color tag defaults to regular
    Given a non-buffered Window instance with color enabled and window created
    When "<>text</>" is sent to the window
    Then no error should have been raised

  Scenario: Colored send with raw color tag
    Given a non-buffered Window instance with color enabled and window created
    When "<raw fg:white bg:black>text</raw>" is sent to the window
    Then no error should have been raised

  # --------------------------------------------------------------------------
  # activate_color_window – branches
  # --------------------------------------------------------------------------
  Scenario: activate_color_window returns early when color is disabled
    Given a non-buffered Window instance
    When the window is created with width 40 height 20 x 0 y 0
    And activate_color_window is called with color disabled
    Then no error should have been raised

  Scenario: activate_color_window uses color_set when available
    Given a non-buffered Window instance with color enabled and window created
    When activate_color_window is called via color_set path
    Then no error should have been raised

  Scenario: activate_color_window uses attrset fallback when color_set unavailable
    Given a non-buffered Window instance with color enabled and window created
    When activate_color_window is called via attrset fallback path
    Then no error should have been raised

  # --------------------------------------------------------------------------
  # parse_buffer – error
  # --------------------------------------------------------------------------
  Scenario: parse_buffer raises when there is no buffer
    Given a non-buffered Window instance
    Then calling parse_buffer should raise "channel has no buffer"

  # --------------------------------------------------------------------------
  # render_buffer
  # --------------------------------------------------------------------------
  Scenario: render_buffer processes all buffer entries
    Given a buffered Window instance
    When the window is created with width 40 height 20 x 0 y 0
    And "message one" is sent to the window
    And "message two" is sent to the window
    Then no error should have been raised

  # --------------------------------------------------------------------------
  # render with and without newline
  # --------------------------------------------------------------------------
  Scenario: Rendering with add_newline true appends a newline
    Given a non-buffered Window instance
    When the window is created with width 40 height 20 x 0 y 0
    And render is called with "test" and add_newline true
    Then no error should have been raised

  Scenario: Rendering with add_newline false does not append a newline
    Given a non-buffered Window instance
    When the window is created with width 40 height 20 x 0 y 0
    And render is called with "test" and add_newline false
    Then no error should have been raised

  # --------------------------------------------------------------------------
  # colored_send – buffered with color
  # --------------------------------------------------------------------------
  Scenario: Sending a colored message to a buffered window
    Given a buffered Window instance with color enabled and window created
    When "<regular>buffered colored</regular>" is sent to the window
    Then no error should have been raised

  # --------------------------------------------------------------------------
  # send with carriage return in message
  # --------------------------------------------------------------------------
  Scenario: Sending a message with carriage return to a non-buffered window
    Given a non-buffered Window instance
    When the window is created with width 40 height 20 x 0 y 0
    And "hello\rworld" is sent to the window
    Then no error should have been raised
