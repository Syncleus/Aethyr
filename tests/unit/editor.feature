Feature: In-game editor module
  In order to allow players to compose multi-line text in-game
  As a game engine component
  I want the Editor module to handle editing commands correctly

  Background:
    Given a stubbed Editor environment

  # ── start_editor ──────────────────────────────────────────────────────

  Scenario: Starting the editor with an empty array buffer
    When the editor is started with an empty array buffer
    Then the editor line should be 0
    And the editor buffer should be empty
    And editing should be true
    And the player should be removed from the room

  Scenario: Starting the editor with a non-empty array buffer
    When the editor is started with array buffer "line one,line two,line three"
    Then the editor line should be 3
    And the editor buffer should have 3 lines

  Scenario: Starting the editor with a string buffer
    When the editor is started with string buffer "line one\nline two"
    Then the editor line should be 2
    And the editor buffer should have 2 lines

  Scenario: Starting the editor with a custom limit
    When the editor is started with limit 5
    Then the editor limit should be 5

  # ── editor_prompt ─────────────────────────────────────────────────────

  Scenario: Displaying the editor prompt
    Given the editor has been started
    When editor_prompt is called
    Then the printed output should contain "<editor>"

  # ── editor_out ────────────────────────────────────────────────────────

  Scenario: Outputting a message through editor_out
    Given the editor has been started
    When editor_out is called with "Hello world"
    Then the send_puts output should contain "<editor>Hello world</editor>"

  # ── editor_echo ───────────────────────────────────────────────────────

  Scenario: Echoing the current buffer
    When the editor is started with array buffer "alpha,beta"
    And editor_echo is called
    Then the printed output should contain "alpha"
    And the printed output should contain "beta"

  # ── editor_append ─────────────────────────────────────────────────────

  Scenario: Appending text to the buffer
    Given the editor has been started
    When editor_append is called with "new line"
    Then the editor buffer should contain "new line"
    And the editor line should be 1

  Scenario: Appending text when already at the limit
    When the editor is started with limit 1
    And editor_append is called with "first"
    And editor_append is called with "overflow"
    Then the puts output should contain "You have run out of room on this document."
    And the editor buffer should not contain "overflow"

  Scenario: Appending text that reaches the limit exactly
    When the editor is started with limit 1
    And editor_append is called with "exactly at limit"
    Then the puts output should contain "You have run out of room on this document."

  # ── editor_input routing ──────────────────────────────────────────────

  Scenario: Input *quit calls editor_quit
    Given the editor has been started
    When editor_input receives "*quit"
    Then the send_puts output should contain "Do you wish to save"

  Scenario: Input *cancel calls editor_quit
    Given the editor has been started
    When editor_input receives "*cancel"
    Then the send_puts output should contain "Do you wish to save"

  Scenario: Input *q calls editor_quit
    Given the editor has been started
    When editor_input receives "*q"
    Then the send_puts output should contain "Do you wish to save"

  Scenario: Input *exit calls editor_quit
    Given the editor has been started
    When editor_input receives "*exit"
    Then the send_puts output should contain "Do you wish to save"

  Scenario: Input *save calls editor_save
    Given the editor has been started
    When editor_input receives "*save"
    Then editing should be false

  Scenario: Input *s calls editor_save
    Given the editor has been started
    When editor_input receives "*s"
    Then editing should be false

  Scenario: Input *clear calls editor_clear
    Given the editor has been started with buffer "something"
    When editor_input receives "*clear"
    Then the editor buffer should be empty
    And the editor line should be 0

  Scenario: Input *c calls editor_clear
    Given the editor has been started with buffer "something"
    When editor_input receives "*c"
    Then the editor buffer should be empty

  Scenario: Input *echo shows the buffer
    When the editor is started with array buffer "test line"
    And editor_input receives "*echo"
    Then the printed output should contain "test line"

  Scenario: Input *show shows the buffer
    When the editor is started with array buffer "test line"
    And editor_input receives "*show"
    Then the printed output should contain "test line"

  Scenario: Input *e shows the buffer
    When the editor is started with array buffer "test line"
    And editor_input receives "*e"
    Then the printed output should contain "test line"

  Scenario: Input *more calls paginator more
    Given the editor has been started
    When editor_input receives "*more"
    Then the more method should have been called

  Scenario: Input *m calls paginator more
    Given the editor has been started
    When editor_input receives "*m"
    Then the more method should have been called

  Scenario: Input *help shows general help
    Given the editor has been started
    When editor_input receives "*help"
    Then the send_puts output should contain "following commands are available"

  Scenario: Input *h shows general help
    Given the editor has been started
    When editor_input receives "*h"
    Then the send_puts output should contain "following commands are available"

  Scenario: Input *line N goes to a line
    When the editor is started with array buffer "a,b,c"
    And editor_input receives "*line 2"
    Then the editor line should be 1

  Scenario: Input *go N goes to a line
    When the editor is started with array buffer "a,b,c"
    And editor_input receives "*go 2"
    Then the editor line should be 1

  Scenario: Input *g N goes to a line
    When the editor is started with array buffer "a,b,c"
    And editor_input receives "*g 2"
    Then the editor line should be 1

  Scenario: Input *l N goes to a line
    When the editor is started with array buffer "a,b,c"
    And editor_input receives "*l 2"
    Then the editor line should be 1

  Scenario: Input *delete N deletes a line
    When the editor is started with array buffer "a,b,c"
    And editor_input receives "*delete 2"
    Then the editor buffer should not contain "b"

  Scenario: Input *dl N deletes a line
    When the editor is started with array buffer "a,b,c"
    And editor_input receives "*dl 2"
    Then the editor buffer should not contain "b"

  Scenario: Input *replace N text replaces a line
    When the editor is started with array buffer "a,b,c"
    And editor_input receives "*replace 2 replaced"
    Then the editor buffer should contain "replaced"
    And the editor buffer should not contain "b"

  Scenario: Input *r N text replaces a line
    When the editor is started with array buffer "a,b,c"
    And editor_input receives "*r 2 replaced"
    Then the editor buffer should contain "replaced"

  Scenario: Input *help save shows save help
    Given the editor has been started
    When editor_input receives "*help save"
    Then the send_puts output should contain "*save will save"

  Scenario: Input *help quit shows quit help
    Given the editor has been started
    When editor_input receives "*help quit"
    Then the send_puts output should contain "*quit will prompt"

  Scenario: Input unknown star command shows error
    Given the editor has been started
    When editor_input receives "*unknown"
    Then the send_puts output should contain "Unknown command"

  Scenario: Input plain text appends to buffer
    Given the editor has been started
    When editor_input receives "some plain text"
    Then the editor buffer should contain "some plain text"

  # ── editor_help with specific topics ──────────────────────────────────

  Scenario: Help for save command
    Given the editor has been started
    When editor_help is called with "save"
    Then the send_puts output should contain "*save will save"

  Scenario: Help for *save command
    Given the editor has been started
    When editor_help is called with "*save"
    Then the send_puts output should contain "*save will save"

  Scenario: Help for quit command
    Given the editor has been started
    When editor_help is called with "quit"
    Then the send_puts output should contain "*quit will prompt"

  Scenario: Help for *quit command
    Given the editor has been started
    When editor_help is called with "*quit"
    Then the send_puts output should contain "*quit will prompt"

  Scenario: Help for echo command
    Given the editor has been started
    When editor_help is called with "echo"
    Then the send_puts output should contain "*echo will show"

  Scenario: Help for *echo command
    Given the editor has been started
    When editor_help is called with "*echo"
    Then the send_puts output should contain "*echo will show"

  Scenario: Help for delete command
    Given the editor has been started
    When editor_help is called with "delete"
    Then the send_puts output should contain "*delete"

  Scenario: Help for *delete command
    Given the editor has been started
    When editor_help is called with "*delete"
    Then the send_puts output should contain "*delete"

  Scenario: Help for line command
    Given the editor has been started
    When editor_help is called with "line"
    Then the send_puts output should contain "*line"

  Scenario: Help for *line command
    Given the editor has been started
    When editor_help is called with "*line"
    Then the send_puts output should contain "*line"

  Scenario: Help for replace command
    Given the editor has been started
    When editor_help is called with "replace"
    Then the send_puts output should contain "*replace"

  Scenario: Help for *replace command
    Given the editor has been started
    When editor_help is called with "*replace"
    Then the send_puts output should contain "*replace"

  Scenario: Help for more command
    Given the editor has been started
    When editor_help is called with "more"
    Then the send_puts output should contain "*more"

  Scenario: Help for *more command
    Given the editor has been started
    When editor_help is called with "*more"
    Then the send_puts output should contain "*more"

  Scenario: Help for nil shows general help
    Given the editor has been started
    When editor_help is called with nil
    Then the send_puts output should contain "following commands are available"

  # ── editor_replace ────────────────────────────────────────────────────

  Scenario: Replace a line past end of document
    When the editor is started with array buffer "a,b"
    And editor_replace is called with line 5 and data "x"
    Then the send_puts output should contain "Cannot go past end of document"

  Scenario: Replace a line before start of document
    When the editor is started with array buffer "a,b"
    And editor_replace is called with line 0 and data "x"
    Then the send_puts output should contain "Cannot go past start of document"

  Scenario: Replace a valid line
    When the editor is started with array buffer "a,b,c"
    And editor_replace is called with line 2 and data "replaced"
    Then the editor buffer should contain "replaced"
    And the send_puts output should contain "Replaced line 2"

  # ── editor_delete ─────────────────────────────────────────────────────

  Scenario: Delete a line past end of document
    When the editor is started with array buffer "a,b"
    And editor_delete is called with line 5
    Then the send_puts output should contain "Cannot go past end of document"

  Scenario: Delete a line before start of document
    When the editor is started with array buffer "a,b"
    And editor_delete is called with line 0
    Then the send_puts output should contain "Cannot go past start of document"

  Scenario: Delete a valid line
    When the editor is started with array buffer "a,b,c"
    And editor_delete is called with line 2
    Then the editor buffer should not contain "b"
    And the send_puts output should contain "Deleted line 2"
    And the editor line should be 2

  Scenario: Delete a line when editor_line is 0
    When the editor is started with array buffer "a"
    And the editor line is set to 0
    And editor_delete is called with line 1
    Then the editor line should be 0

  # ── editor_go ─────────────────────────────────────────────────────────

  Scenario: Go to a line past end of document
    When the editor is started with array buffer "a,b"
    And editor_go is called with line 10
    Then the send_puts output should contain "Cannot go past end of document"

  Scenario: Go to a line before start of document
    When the editor is started with array buffer "a,b"
    And editor_go is called with line 0
    Then the send_puts output should contain "Cannot go past start of document"

  Scenario: Go to a valid line
    When the editor is started with array buffer "a,b,c"
    And editor_go is called with line 2
    Then the editor line should be 1
    And the send_puts output should contain "Moved to before line 2"

  # ── editor_clear ──────────────────────────────────────────────────────

  Scenario: Clearing the editor buffer
    When the editor is started with array buffer "a,b,c"
    And editor_clear is called
    Then the editor buffer should be empty
    And the editor line should be 0
    And the send_puts output should contain "Cleared document"

  # ── editor_quit ───────────────────────────────────────────────────────

  Scenario: Quitting the editor and choosing yes to save
    Given the editor has been started
    When editor_quit is called
    And the expect callback receives "yes"
    Then editing should be false
    And the callback result should not be nil

  Scenario: Quitting the editor and choosing no to discard
    Given the editor has been started
    When editor_quit is called
    And the expect callback receives "no"
    Then editing should be false
    And the callback result should be nil

  Scenario: Quitting the editor and choosing cancel to resume
    Given the editor has been started
    When editor_quit is called
    And the expect callback receives "cancel"
    Then editing should be true
    And the send_puts output should contain "Resuming editing"

  # ── editor_save ───────────────────────────────────────────────────────

  Scenario: Saving the editor
    Given the editor has been started
    When editor_save is called
    Then editing should be false
    And the callback result should not be nil
    And the editor buffer should be nil
    And the editor callback should be nil

  # ── editor_really_quit ────────────────────────────────────────────────

  Scenario: Really quitting the editor without saving
    Given the editor has been started
    When editor_really_quit is called
    Then editing should be false
    And the callback result should be nil
    And the editor buffer should be nil
    And the editor callback should be nil

  # ── fix_player ────────────────────────────────────────────────────────

  Scenario: Fixing the player back into the room
    Given the editor has been started
    When fix_player is called
    Then the player should be back in the room
