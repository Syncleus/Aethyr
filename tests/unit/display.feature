Feature: Display rendering engine
  The Display class manages the ncurses-based terminal rendering
  including window layout, color management, input handling, and
  progress bar generation.

  Background:
    Given a stubbed Display environment

  # ---------------------------------------------------------------------------
  #  Constructor
  # ---------------------------------------------------------------------------
  Scenario: Creating a Display with default color settings
    When I create a Display with default colors
    Then the display should have default height 43
    And the display should have default width 80
    And the display layout_type should be :basic
    And the display use_color should be false

  Scenario: Creating a Display with custom color settings
    When I create a Display with custom colors
    Then the display should use the custom color settings

  # ---------------------------------------------------------------------------
  #  init_colors
  # ---------------------------------------------------------------------------
  Scenario: Initializing colors
    When I create a Display with default colors
    And I call init_colors on the display
    Then the display use_color should be true

  # ---------------------------------------------------------------------------
  #  selected= and selected
  # ---------------------------------------------------------------------------
  Scenario: Setting and getting selected window
    When I create a Display with default colors
    And I set selected to :main
    Then the selected window should be :main

  Scenario: Getting selected when no window is selected returns :input
    When I create a Display with default colors
    And I deselect all windows
    Then the selected window should be :input

  # ---------------------------------------------------------------------------
  #  layout types
  # ---------------------------------------------------------------------------
  Scenario: Wide layout with sufficient resolution
    When I create a Display with default colors
    And I set resolution to 300 by 60
    And I set layout to :wide
    Then the layout_type should be :wide

  Scenario: Full layout at 249 width
    When I create a Display with default colors
    And I set resolution to 249 by 60
    And I set layout to :full
    Then the layout_type should be :full

  Scenario: Partial layout at 166 width
    When I create a Display with default colors
    And I set resolution to 166 by 60
    And I set layout to :partial
    Then the layout_type should be :partial

  Scenario: Basic layout at small resolution
    When I create a Display with default colors
    And I set resolution to 80 by 43
    And I set layout to :basic
    Then the layout_type should be :basic

  Scenario: Wide layout falls back to full when width is between 249 and 300
    When I create a Display with default colors
    And I set resolution to 260 by 60
    And I set layout to :wide
    Then the layout_type should be :wide

  Scenario: Full layout falls back to partial when width is between 166 and 249
    When I create a Display with default colors
    And I set resolution to 200 by 60
    And I set layout to :full
    Then the layout_type should be :full

  # ---------------------------------------------------------------------------
  #  resolution
  # ---------------------------------------------------------------------------
  Scenario: Getting and setting resolution
    When I create a Display with default colors
    Then the resolution should be 80 by 43
    When I set resolution to 120 by 50
    Then the resolution should be 120 by 50

  # ---------------------------------------------------------------------------
  #  global_refresh
  # ---------------------------------------------------------------------------
  Scenario: Global refresh flag
    When I create a Display with default colors
    Then global_refresh should return nil or false
    When I set resolution to 100 by 50
    Then global_refresh should return true
    And global_refresh should return nil or false

  # ---------------------------------------------------------------------------
  #  echo methods
  # ---------------------------------------------------------------------------
  Scenario: Echo state management
    When I create a Display with default colors
    Then echo? should be true
    When I call echo_off
    Then echo? should be false
    When I call echo_on
    Then echo? should be true

  # ---------------------------------------------------------------------------
  #  recv
  # ---------------------------------------------------------------------------
  Scenario: Receiving input when read_line returns nil
    When I create a Display with default colors
    And I call recv and read_line returns nil
    Then recv should return nil

  Scenario: Receiving input when read_line returns a string
    When I create a Display with default colors
    And I call recv and read_line returns "hello"
    Then recv should return "hello" with newline

  # ---------------------------------------------------------------------------
  #  send_raw
  # ---------------------------------------------------------------------------
  Scenario: Sending raw message
    When I create a Display with default colors
    And I send_raw "test message"
    Then the socket should have received "test message"

  # ---------------------------------------------------------------------------
  #  send
  # ---------------------------------------------------------------------------
  Scenario: Sending message to existing window
    When I create a Display with default colors
    And I send "hello world" to message_type :main
    Then the main window should have received the message

  Scenario: Sending message to non-existing window type
    When I create a Display with default colors
    And I send "hello" to a non-existing message_type
    Then the main window should have received the message as fallback

  Scenario: Sending message with internal_clear
    When I create a Display with default colors
    And I send "cleared" with internal_clear to :main
    Then the main window should have been cleared and received the message

  # ---------------------------------------------------------------------------
  #  close
  # ---------------------------------------------------------------------------
  Scenario: Closing the display
    When I create a Display with default colors
    And I close the display
    Then the socket should be closed

  # ---------------------------------------------------------------------------
  #  to_default_colors
  # ---------------------------------------------------------------------------
  Scenario: Default color settings
    When I create a Display with default colors
    Then the color settings should contain key "roomtitle"
    And the color settings should contain key "regular"
    And the color settings should contain key "fire"

  # ---------------------------------------------------------------------------
  #  set_color
  # ---------------------------------------------------------------------------
  Scenario: Setting a valid color
    When I create a Display with default colors
    And I set color "roomtitle" to "fg:red bold"
    Then the set_color result should contain "Set roomtitle"

  Scenario: Setting an invalid color code
    When I create a Display with default colors
    And I set color "nonexistent" to "fg:red"
    Then the set_color result should contain "No such setting"

  Scenario: Setting color when use_color is false clears existing settings first
    When I create a Display with default colors
    And use_color is false
    And I set color "roomtitle" to "fg:blue"
    Then use_color should be true

  # ---------------------------------------------------------------------------
  #  show_color_config
  # ---------------------------------------------------------------------------
  Scenario: Showing color configuration when disabled
    When I create a Display with default colors
    Then show_color_config should contain "Colors are currently"
    And show_color_config should contain "Disabled"
    And show_color_config should contain "Room Title"

  Scenario: Showing color configuration when enabled
    When I create a Display with default colors
    And I enable use_color
    Then show_color_config should contain "Enabled"

  # ---------------------------------------------------------------------------
  #  refresh_watch_windows
  # ---------------------------------------------------------------------------
  Scenario: Refresh watch windows with look window existing and room present
    When I create a Display with default colors
    And the look window exists with a room
    And I call refresh_watch_windows
    Then the look window should have received look output

  Scenario: Refresh watch windows with look window existing and no room
    When I create a Display with default colors
    And the look window exists without a room
    And I call refresh_watch_windows
    Then the look window should show nothing to look at

  Scenario: Refresh watch windows with map window existing and room present
    When I create a Display with default colors
    And the map window exists with a room
    And I call refresh_watch_windows
    Then the map window should have received map output

  Scenario: Refresh watch windows with map window existing and no room
    When I create a Display with default colors
    And the map window exists without a room
    Then the map window should show no map

  Scenario: Refresh watch windows with quick_bar window existing
    When I create a Display with default colors
    And the quick_bar window exists
    And I call refresh_watch_windows
    Then the quick_bar should have received progress output

  Scenario: Refresh watch windows with status window existing
    When I create a Display with default colors
    And the status window exists
    And I call refresh_watch_windows
    Then the status window should have received status output

  # ---------------------------------------------------------------------------
  #  set_term
  # ---------------------------------------------------------------------------
  Scenario: Setting the terminal
    When I create a Display with default colors
    And I call set_term
    Then Ncurses.set_term should have been called

  # ---------------------------------------------------------------------------
  #  read_line via recv - input processing
  # ---------------------------------------------------------------------------
  Scenario: read_line processes none stage
    When I create a Display with default colors
    And I initiate recv to start read_line
    Then recv should return nil for the first call

  Scenario: read_line handles return key
    When I create a Display with default colors
    And I simulate typing "abc" and pressing return
    Then the returned input should be "abc"

  Scenario: read_line handles backspace key
    When I create a Display with default colors
    And I simulate typing "ab" then backspace then "c" and return
    Then the returned input should be "ac"

  Scenario: read_line handles left arrow key
    When I create a Display with default colors
    And I simulate left arrow key press
    Then recv should return nil

  Scenario: read_line handles right arrow key
    When I create a Display with default colors
    And I simulate right arrow key press
    Then recv should return nil

  Scenario: read_line handles up arrow key
    When I create a Display with default colors
    And I simulate up arrow key press
    Then recv should return nil

  Scenario: read_line handles down arrow key
    When I create a Display with default colors
    And I simulate down arrow key press
    Then recv should return nil

  Scenario: read_line handles escape sequence for left arrow
    When I create a Display with default colors
    And I simulate escape sequence for left arrow
    Then recv should return nil

  Scenario: read_line handles escape sequence for right arrow
    When I create a Display with default colors
    And I simulate escape sequence for right arrow
    Then recv should return nil

  Scenario: read_line handles escape sequence for up arrow
    When I create a Display with default colors
    And I simulate escape sequence for up arrow
    Then recv should return nil

  Scenario: read_line handles escape sequence for down arrow
    When I create a Display with default colors
    And I simulate escape sequence for down arrow
    Then recv should return nil

  Scenario: read_line handles page up escape sequence
    When I create a Display with default colors
    And I simulate page up key press
    Then recv should return nil

  Scenario: read_line handles page down escape sequence
    When I create a Display with default colors
    And I simulate page down key press
    Then recv should return nil

  Scenario: read_line handles page up with non-input selected
    When I create a Display with default colors
    And I set selected to :main
    And I simulate page up key press for non-input window
    Then recv should return nil

  Scenario: read_line handles page down with non-input selected
    When I create a Display with default colors
    And I set selected to :main
    And I simulate page down key press for non-input window
    Then recv should return nil

  Scenario: read_line handles unknown escape sequence
    When I create a Display with default colors
    And I simulate unknown escape sequence
    Then recv should return nil

  Scenario: read_line handles unknown key in escape [27,91] state
    When I create a Display with default colors
    And I simulate unknown key in bracket escape
    Then recv should return nil

  Scenario: read_line handles unknown key in page up state
    When I create a Display with default colors
    And I simulate unknown key in page up state
    Then recv should return nil

  Scenario: read_line handles unknown key in page down state
    When I create a Display with default colors
    And I simulate unknown key in page down state
    Then recv should return nil

  Scenario: read_line handles unknown escape completely
    When I create a Display with default colors
    And I simulate unknown escape completely
    Then recv should return nil

  Scenario: read_line handles tab cycling from input to look
    When I create a Display with default colors
    And the look window is set to exist
    And I simulate tab key press
    Then the selected window should be :look

  Scenario: read_line handles tab cycling from input to main when no look
    When I create a Display with default colors
    And no look window exists
    And I simulate tab key press
    Then the selected window should be :main

  Scenario: read_line handles tab from main to chat
    When I create a Display with default colors
    And the chat window is set to exist
    And I set selected to :main
    And I simulate tab key press
    Then the selected window should be :chat

  Scenario: read_line handles tab from main to status when no chat
    When I create a Display with default colors
    And no chat window exists but status exists
    And I set selected to :main
    And I simulate tab key press
    Then the selected window should be :status

  Scenario: read_line handles tab from main to input when no chat or status
    When I create a Display with default colors
    And no chat or status windows exist
    And I set selected to :main
    And I simulate tab key press
    Then the selected window should be :input

  Scenario: read_line handles tab from map to main
    When I create a Display with default colors
    And I set selected to :map
    And I simulate tab key press
    Then the selected window should be :main

  Scenario: read_line handles tab from look to map
    When I create a Display with default colors
    And the map window is set to exist
    And I set selected to :look
    And I simulate tab key press
    Then the selected window should be :map

  Scenario: read_line handles tab from look to input when no map
    When I create a Display with default colors
    And no map window exists
    And I set selected to :look
    And I simulate tab key press
    Then the selected window should be :input

  Scenario: read_line handles tab from chat to status
    When I create a Display with default colors
    And the status window is set to exist
    And I set selected to :chat
    And I simulate tab key press
    Then the selected window should be :status

  Scenario: read_line handles tab from chat to input when no status
    When I create a Display with default colors
    And no status window exists
    And I set selected to :chat
    And I simulate tab key press
    Then the selected window should be :input

  Scenario: read_line handles tab from status to input
    When I create a Display with default colors
    And I set selected to :status
    And I simulate tab key press
    Then the selected window should be :input

  Scenario: read_line handles tab from unknown to input
    When I create a Display with default colors
    And I set selected to :unknown_window
    And I simulate tab key press
    Then the selected window should be :input

  Scenario: read_line handles unidentified key press
    When I create a Display with default colors
    And I simulate an unidentified key press
    Then recv should return nil

  Scenario: read_line handles backspace at position 0
    When I create a Display with default colors
    And I simulate backspace at cursor position 0
    Then recv should return nil

  Scenario: read_line with echo off
    When I create a Display with default colors
    And I call echo_off
    And I simulate typing "secret" and pressing return
    Then the returned input should be "secret"

  # ---------------------------------------------------------------------------
  #  generate_progress (private class method)
  # ---------------------------------------------------------------------------
  Scenario: Generate progress bar with vertical smooth style at low percentage
    When I generate a progress bar with width 20 and percentage 0.1
    Then the progress bar should contain block characters

  Scenario: Generate progress bar with horizontal smooth style
    When I generate a progress bar with horizontal_smooth style at 0.5
    Then the progress bar should contain block characters

  Scenario: Generate progress bar at zero percent
    When I generate a progress bar with width 20 and percentage 0.0
    Then the progress bar should contain bracket characters

  Scenario: Generate progress bar at full percent
    When I generate a progress bar with width 20 and percentage 1.0
    Then the progress bar should contain block characters

  Scenario Outline: Generate progress bar at various percentages for fractional blocks
    When I generate a progress bar with width 20 and percentage <percent>
    Then the progress bar should contain block characters

    Examples:
      | percent |
      | 0.12    |
      | 0.25    |
      | 0.37    |
      | 0.50    |
      | 0.62    |
      | 0.75    |
      | 0.87    |
      | 0.99    |

  Scenario: Generate horizontal smooth progress bar at various fractions
    When I generate horizontal progress bars at all fraction levels
    Then all progress bars should be non-empty strings

  Scenario: Generate progress bar with label
    When I generate a progress bar with label "HP: "
    Then the progress bar should contain "HP: "
