Feature: Authentication flow in Login module

  The Login module handles the complete authentication lifecycle for
  the Aethyr MUD engine: colour resolution, server menu navigation,
  existing-player login, new-character registration, password validation,
  and character-name validation.

  # ---------------------------------------------------------------------------
  # receive_data – basic I/O plumbing
  # ---------------------------------------------------------------------------

  Scenario: authentication receive_data returns false when connection is closed
    Given an authentication login handler
    And the authentication connection is closed
    When authentication receive_data is called
    Then the authentication result should be false

  Scenario: authentication receive_data returns false when display returns nil
    Given an authentication login handler
    And the authentication display returns nil on recv
    When authentication receive_data is called
    Then the authentication result should be false

  Scenario: authentication receive_data returns false when display returns empty string
    Given an authentication login handler
    And the authentication display returns empty string on recv
    When authentication receive_data is called
    Then the authentication result should be false

  Scenario: authentication receive_data buffers incomplete lines
    Given an authentication login handler
    And the authentication display returns "partial" without newline on recv
    When authentication receive_data is called
    Then the authentication result should be true
    And the authentication input buffer should contain "partial"

  Scenario: authentication receive_data joins buffered data on newline
    Given an authentication login handler
    And the authentication input buffer already contains "hel"
    And the authentication display returns "lo\n" on recv
    And the authentication state is "server_menu"
    When authentication receive_data is called
    Then the authentication result should be true
    And the authentication input buffer should be empty

  Scenario: authentication receive_data preserves blank input lines
    Given an authentication login handler
    And the authentication display returns " \n" on recv
    And the authentication state is "server_menu"
    When authentication receive_data is called
    Then the authentication result should be true

  # ---------------------------------------------------------------------------
  # receive_data – state dispatch
  # ---------------------------------------------------------------------------

  Scenario: authentication receive_data dispatches initial state
    Given an authentication login handler
    And the authentication state is "initial"
    And the authentication display returns "anything\n" on recv
    When authentication receive_data is called
    Then the authentication state should be "resolution"

  Scenario: authentication receive_data dispatches resolution state
    Given an authentication login handler
    And the authentication state is "resolution"
    And the authentication display returns "y\n" on recv
    When authentication receive_data is called
    Then the authentication state should be "server_menu"

  Scenario: authentication receive_data dispatches server_menu state
    Given an authentication login handler
    And the authentication state is "server_menu"
    And the authentication display returns "2\n" on recv
    When authentication receive_data is called
    Then the authentication state should be "new_name"

  Scenario: authentication receive_data dispatches login_name state
    Given an authentication login handler
    And the authentication state is "login_name"
    And the authentication manager reports player "Tester" exists
    And the authentication display returns "Tester\n" on recv
    When authentication receive_data is called
    Then the authentication state should be "login_password"

  Scenario: authentication receive_data dispatches login_password state
    Given an authentication login handler
    And the authentication state is "login_password"
    And the authentication login name is "Tester"
    And the authentication manager loads player "Tester" successfully
    When authentication receive_data with password "secret\n" is called
    Then the authentication player should be set

  Scenario: authentication receive_data dispatches new_name state
    Given an authentication login handler
    And the authentication state is "new_name"
    And the authentication manager reports player "Newbie" does not exist
    And the authentication display returns "Newbie\n" on recv
    When authentication receive_data is called
    Then the authentication state should be "new_sex"

  Scenario: authentication receive_data dispatches new_password state
    Given an authentication login handler
    And the authentication state is "new_password"
    And the authentication display returns "validpass\n" on recv
    When authentication receive_data is called
    Then the authentication state should be "new_color"

  Scenario: authentication receive_data dispatches new_sex state
    Given an authentication login handler
    And the authentication state is "new_sex"
    And the authentication display returns "m\n" on recv
    When authentication receive_data is called
    Then the authentication state should be "new_password"

  Scenario: authentication receive_data dispatches new_color state with yes
    Given an authentication login handler
    And the authentication state is "new_color"
    And the authentication new name is "Newguy"
    And the authentication sex is "m"
    And the authentication new password is "secret"
    And the authentication display returns "y\n" on recv
    When authentication receive_data is called
    Then the authentication player should be set

  Scenario: authentication receive_data dispatches unknown state
    Given an authentication login handler
    And the authentication state is "unknown_bogus"
    And the authentication display returns "test\n" on recv
    When authentication receive_data is called
    Then the authentication result should be true

  Scenario: authentication receive_data invokes expect callback
    Given an authentication login handler
    And the authentication has an expect callback
    And the authentication display returns "callbackdata\n" on recv
    When authentication receive_data is called
    Then the authentication callback should have received "callbackdata"

  Scenario: authentication receive_data invokes editor_input when editing
    Given an authentication login handler
    And the authentication is in editing mode
    And the authentication display returns "some text\n" on recv
    When authentication receive_data is called
    Then the authentication editor should have received input

  Scenario: authentication receive_data invokes player handle_input when player set
    Given an authentication login handler
    And the authentication has a player set
    And the authentication display returns "look\n" on recv
    When authentication receive_data is called
    Then the authentication player should have received handle_input

  # ---------------------------------------------------------------------------
  # show_initial / show_resolution_prompt
  # ---------------------------------------------------------------------------

  Scenario: authentication show_initial sets resolution state
    Given an authentication login handler
    When authentication show_initial is called
    Then the authentication state should be "resolution"
    And the authentication output should include "color"

  # ---------------------------------------------------------------------------
  # do_resolution
  # ---------------------------------------------------------------------------

  Scenario: authentication do_resolution with yes enables colors
    Given an authentication login handler
    When authentication do_resolution is called with "y"
    Then the authentication display should have initialized colors
    And the authentication state should be "server_menu"

  Scenario: authentication do_resolution with capital Y enables colors
    Given an authentication login handler
    When authentication do_resolution is called with "Y"
    Then the authentication display should have initialized colors
    And the authentication state should be "server_menu"

  Scenario: authentication do_resolution with no skips colors
    Given an authentication login handler
    When authentication do_resolution is called with "n"
    Then the authentication display should not have initialized colors
    And the authentication state should be "server_menu"

  Scenario: authentication do_resolution with capital N skips colors
    Given an authentication login handler
    When authentication do_resolution is called with "N"
    Then the authentication display should not have initialized colors
    And the authentication state should be "server_menu"

  Scenario: authentication do_resolution with empty defaults to colors
    Given an authentication login handler
    When authentication do_resolution is called with ""
    Then the authentication display should have initialized colors
    And the authentication state should be "server_menu"

  Scenario: authentication do_resolution with invalid input re-prompts
    Given an authentication login handler
    When authentication do_resolution is called with "123"
    Then the authentication state should be "resolution"

  # ---------------------------------------------------------------------------
  # show_server_menu
  # ---------------------------------------------------------------------------

  Scenario: authentication show_server_menu displays options
    Given an authentication login handler
    When authentication show_server_menu is called
    Then the authentication state should be "server_menu"
    And the authentication output should include "Login"

  # ---------------------------------------------------------------------------
  # do_server_menu
  # ---------------------------------------------------------------------------

  Scenario: authentication do_server_menu option 1 prompts for character name
    Given an authentication login handler
    When authentication do_server_menu is called with "1"
    Then the authentication state should be "login_name"
    And the authentication output should include "Character name"

  Scenario: authentication do_server_menu option 2 starts new character
    Given an authentication login handler
    When authentication do_server_menu is called with "2"
    Then the authentication state should be "new_name"

  Scenario: authentication do_server_menu option 3 says farewell
    Given an authentication login handler
    When authentication do_server_menu is called with "3"
    Then the authentication output should include "Farewell"
    And the authentication connection should be closing

  Scenario: authentication do_server_menu with alphabetic input calls login_name directly
    Given an authentication login handler
    And the authentication manager reports player "Testchar" exists
    When authentication do_server_menu is called with "Testchar"
    Then the authentication state should be "login_password"

  Scenario: authentication do_server_menu with invalid input re-shows menu
    Given an authentication login handler
    When authentication do_server_menu is called with "!@#"
    Then the authentication state should be "server_menu"

  # ---------------------------------------------------------------------------
  # login_name
  # ---------------------------------------------------------------------------

  Scenario: authentication login_name with valid existing player prompts for password
    Given an authentication login handler
    And the authentication manager reports player "Hero" exists
    When authentication login_name is called with "Hero"
    Then the authentication state should be "login_password"
    And the authentication output should include "Password"

  Scenario: authentication login_name with non-existing player shows error
    Given an authentication login handler
    And the authentication manager reports player "Nobody" does not exist
    When authentication login_name is called with "Nobody"
    Then the authentication output should include "no such character"
    And the authentication state should be "server_menu"

  Scenario: authentication login_name with invalid characters shows error
    Given an authentication login handler
    When authentication login_name is called with "bad name 123"
    Then the authentication output should include "no such character"
    And the authentication state should be "server_menu"

  # ---------------------------------------------------------------------------
  # login_password – success
  # ---------------------------------------------------------------------------

  Scenario: authentication login_password succeeds for valid credentials
    Given an authentication login handler
    And the authentication login name is "Tester"
    And the authentication manager loads player "Tester" successfully
    When authentication login_password is called with "correctpass"
    Then the authentication player should be set

  Scenario: authentication login_password sets admin when name matches config
    Given an authentication login handler
    And the authentication login name is "Admin"
    And the authentication manager loads admin player "Admin" successfully
    And the authentication admin config is "Admin"
    When authentication login_password is called with "adminpass"
    Then the authentication player should be admin

  Scenario: authentication login_password outputs motd when motd.txt exists
    Given an authentication login handler
    And the authentication login name is "Tester"
    And the authentication manager loads player "Tester" successfully
    And a motd.txt file exists with content "Welcome back!"
    When authentication login_password is called with "password"
    Then the authentication player output should include "News"

  # ---------------------------------------------------------------------------
  # login_password – failure modes
  # ---------------------------------------------------------------------------

  Scenario: authentication login_password handles UnknownCharacter
    Given an authentication login handler
    And the authentication login name is "Ghost"
    And the authentication manager raises UnknownCharacter for "Ghost"
    When authentication login_password is called with "anything"
    Then the authentication output should include "does not appear to exist"
    And the authentication state should be "server_menu"

  Scenario: authentication login_password handles BadPassword
    Given an authentication login handler
    And the authentication login name is "Tester"
    And the authentication manager raises BadPassword for "Tester"
    And the authentication manager reports player "Tester" exists
    When authentication login_password is called with "wrongpass"
    Then the authentication output should include "Incorrect password"

  Scenario: authentication login_password closes after too many bad passwords
    Given an authentication login handler
    And the authentication login name is "Tester"
    And the authentication password attempts is 3
    And the authentication manager raises BadPassword for "Tester"
    When authentication login_password is called with "wrongagain"
    Then the authentication output should include "Too many incorrect"
    And the authentication connection should have been closed

  Scenario: authentication login_password handles CharacterAlreadyLoaded
    Given an authentication login handler
    And the authentication login name is "Active"
    And the authentication manager raises CharacterAlreadyLoaded for "Active"
    When authentication login_password is called with "password"
    Then the authentication output should include "already logged in"
    And the authentication state should be "server_menu"

  Scenario: authentication login_password handles nil player
    Given an authentication login handler
    And the authentication login name is "Broken"
    And the authentication manager loads nil for "Broken"
    When authentication login_password is called with "password"
    Then the authentication output should include "error occurred"
    And the authentication state should be "server_menu"

  # ---------------------------------------------------------------------------
  # ask_new_name / new_name
  # ---------------------------------------------------------------------------

  Scenario: authentication ask_new_name prompts for name
    Given an authentication login handler
    When authentication ask_new_name is called
    Then the authentication state should be "new_name"
    And the authentication output should include "character name"

  Scenario: authentication new_name with nil data re-asks
    Given an authentication login handler
    When authentication new_name is called with nil
    Then the authentication state should be "new_name"

  Scenario: authentication new_name with existing name shows error
    Given an authentication login handler
    And the authentication manager reports player "Existing" exists
    When authentication new_name is called with "Existing"
    Then the authentication output should include "already exists"
    And the authentication state should be "new_name"

  Scenario: authentication new_name too long shows error
    Given an authentication login handler
    When authentication new_name is called with "Averylongnamethatexceedslimit"
    Then the authentication output should include "less than 20"
    And the authentication state should be "new_name"

  Scenario: authentication new_name too short shows error
    Given an authentication login handler
    When authentication new_name is called with "Ab"
    Then the authentication output should include "longer than 2"
    And the authentication state should be "new_name"

  Scenario: authentication new_name with invalid characters shows error
    Given an authentication login handler
    When authentication new_name is called with "Bad123"
    Then the authentication output should include "Only letters"
    And the authentication state should be "new_name"

  Scenario: authentication new_name with uppercase middle is auto-capitalized and proceeds
    Given an authentication login handler
    And the authentication manager reports player "Badname" does not exist
    When authentication new_name is called with "BaDnAmE"
    Then the authentication state should be "new_sex"

  Scenario: authentication new_name with valid name proceeds to ask sex
    Given an authentication login handler
    And the authentication manager reports player "Validname" does not exist
    When authentication new_name is called with "Validname"
    Then the authentication state should be "new_sex"

  # ---------------------------------------------------------------------------
  # ask_sex / new_sex
  # ---------------------------------------------------------------------------

  Scenario: authentication ask_sex prompts for sex
    Given an authentication login handler
    When authentication ask_sex is called
    Then the authentication state should be "new_sex"
    And the authentication output should include "Sex"

  Scenario: authentication new_sex with male proceeds to password
    Given an authentication login handler
    When authentication new_sex is called with "male"
    Then the authentication state should be "new_password"

  Scenario: authentication new_sex with female proceeds to password
    Given an authentication login handler
    When authentication new_sex is called with "female"
    Then the authentication state should be "new_password"

  Scenario: authentication new_sex with capital M proceeds
    Given an authentication login handler
    When authentication new_sex is called with "M"
    Then the authentication state should be "new_password"

  Scenario: authentication new_sex with invalid input re-asks
    Given an authentication login handler
    When authentication new_sex is called with "x"
    Then the authentication state should be "new_sex"

  # ---------------------------------------------------------------------------
  # ask_password / new_password
  # ---------------------------------------------------------------------------

  Scenario: authentication ask_password prompts for password
    Given an authentication login handler
    When authentication ask_password is called
    Then the authentication state should be "new_password"
    And the authentication display should have echo off

  Scenario: authentication new_password with valid password proceeds
    Given an authentication login handler
    When authentication new_password is called with "abcdef"
    Then the authentication state should be "new_color"
    And the authentication display should have echo on

  Scenario: authentication new_password too short re-asks
    Given an authentication login handler
    When authentication new_password is called with "abc"
    Then the authentication state should be "new_password"

  Scenario: authentication new_password too long re-asks
    Given an authentication login handler
    When authentication new_password is called with "aaaaabbbbbcccccddddde"
    Then the authentication state should be "new_password"

  Scenario: authentication new_password with special chars re-asks
    Given an authentication login handler
    When authentication new_password is called with "pass word!"
    Then the authentication state should be "new_password"

  # ---------------------------------------------------------------------------
  # ask_color / new_color
  # ---------------------------------------------------------------------------

  Scenario: authentication ask_color prompts for color preference
    Given an authentication login handler
    When authentication ask_color is called
    Then the authentication state should be "new_color"
    And the authentication output should include "color"

  Scenario: authentication new_color with yes creates player
    Given an authentication login handler
    And the authentication new name is "Hero"
    And the authentication sex is "m"
    And the authentication new password is "secret"
    When authentication new_color is called with "yes"
    Then the authentication player should be set

  Scenario: authentication new_color with no creates player
    Given an authentication login handler
    And the authentication new name is "Hero"
    And the authentication sex is "m"
    And the authentication new password is "secret"
    When authentication new_color is called with "no"
    Then the authentication player should be set

  Scenario: authentication new_color with invalid input re-asks
    Given an authentication login handler
    When authentication new_color is called with "maybe"
    Then the authentication state should be "new_color"

  # ---------------------------------------------------------------------------
  # create_new_player
  # ---------------------------------------------------------------------------

  Scenario: authentication create_new_player creates fully equipped player
    Given an authentication login handler
    And the authentication new name is "Freshchar"
    And the authentication sex is "f"
    And the authentication new password is "password123"
    When authentication create_new_player is called
    Then the authentication player should be set
    And the authentication output should include "HELP"
    And the authentication final state should be nil

  Scenario: authentication create_new_player grants admin to matching name
    Given an authentication login handler
    And the authentication new name is "Admin"
    And the authentication sex is "m"
    And the authentication new password is "adminpass"
    And the authentication admin config is "Admin"
    When authentication create_new_player is called
    Then the authentication player should be admin
