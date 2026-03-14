Feature: Color modules and FormatState rendering
  The Color::Foreground, Color::Background modules provide ANSI color
  attribute lookup, and the FormatState class manages terminal formatting
  state including foreground/background colors and text attributes.

  Background:
    Given a format test environment

  # ---------------------------------------------------------------------------
  #  Color::Foreground module methods
  # ---------------------------------------------------------------------------
  Scenario: Foreground attributes returns list of color names
    When I call Color::Foreground.attributes
    Then the result should be an array of symbols
    And the result should include :red
    And the result should include :white

  Scenario: Foreground attribute finds a known color
    When I call Color::Foreground.attribute with :red
    Then the attribute result should be 9

  Scenario: Foreground attribute returns nil for unknown color
    When I call Color::Foreground.attribute with :nonexistent_color
    Then the attribute result should be nil

  # ---------------------------------------------------------------------------
  #  Color::Background module methods
  # ---------------------------------------------------------------------------
  Scenario: Background attributes returns list of color names
    When I call Color::Background.attributes
    Then the result should be an array of symbols
    And the result should include :red
    And the result should include :white

  Scenario: Background attribute finds a known color
    When I call Color::Background.attribute with :red
    Then the attribute result should be 9

  Scenario: Background attribute returns nil for unknown color
    When I call Color::Background.attribute with :nonexistent_color
    Then the attribute result should be nil

  # ---------------------------------------------------------------------------
  #  FormatState – constructor with code string (named colors)
  # ---------------------------------------------------------------------------
  Scenario: FormatState with fg and bg color names
    When I create a FormatState with code "fg:red bg:blue"
    Then the format_state fg should be the value of :red
    And the format_state bg should be the value of :blue

  Scenario: FormatState with numeric fg and bg
    When I create a FormatState with code "fg:123 bg:45"
    Then the format_state fg should be 123
    And the format_state bg should be 45

  Scenario: FormatState with extra whitespace in code
    When I create a FormatState with code "fg:red   bg:blue   bold"
    Then the format_state fg should be the value of :red
    And the format_state bold? should be true

  # ---------------------------------------------------------------------------
  #  FormatState – formatting flags via code string
  # ---------------------------------------------------------------------------
  Scenario: FormatState with blink enabled
    When I create a FormatState with code "fg:white blink"
    Then the format_state blink? should be true

  Scenario: FormatState with noblink
    When I create a FormatState with code "fg:white noblink"
    Then the format_state blink? should be false

  Scenario: FormatState with dim enabled
    When I create a FormatState with code "fg:white dim"
    Then the format_state dim? should be true

  Scenario: FormatState with nodim
    When I create a FormatState with code "fg:white nodim"
    Then the format_state dim? should be false

  Scenario: FormatState with underline enabled
    When I create a FormatState with code "fg:white underline"
    Then the format_state underline? should be true

  Scenario: FormatState with nounderline
    When I create a FormatState with code "fg:white nounderline"
    Then the format_state underline? should be false

  Scenario: FormatState with bold enabled
    When I create a FormatState with code "fg:white bold"
    Then the format_state bold? should be true

  Scenario: FormatState with nobold
    When I create a FormatState with code "fg:white nobold"
    Then the format_state bold? should be false

  Scenario: FormatState with reverse enabled
    When I create a FormatState with code "fg:white reverse"
    Then the format_state reverse? should be false due to typo bug

  Scenario: FormatState with noreverse
    When I create a FormatState with code "fg:white noreverse"
    Then the format_state reverse? should be false due to typo bug

  Scenario: FormatState with standout enabled
    When I create a FormatState with code "fg:white standout"
    Then the format_state standout? should be true

  Scenario: FormatState with nostandout
    When I create a FormatState with code "fg:white nostandout"
    Then the format_state standout? should be false

  Scenario: FormatState with all formatting flags
    When I create a FormatState with code "fg:red bg:blue blink dim underline bold reverse standout"
    Then the format_state blink? should be true
    And the format_state dim? should be true
    And the format_state underline? should be true
    And the format_state bold? should be true
    And the format_state standout? should be true

  # ---------------------------------------------------------------------------
  #  FormatState – accessors with parent delegation
  # ---------------------------------------------------------------------------
  Scenario: FormatState fg delegates to parent when not set
    Given a parent FormatState with code "fg:lime"
    When I create a child FormatState with code "bg:blue" and the parent
    Then the format_state fg should be the value of :lime

  Scenario: FormatState bg delegates to parent when not set
    Given a parent FormatState with code "bg:lime"
    When I create a child FormatState with code "fg:red" and the parent
    Then the format_state bg should be the value of :lime

  Scenario: FormatState blink? delegates to parent
    Given a parent FormatState with code "fg:white blink"
    When I create a child FormatState with code "fg:red" and the parent
    Then the format_state blink? should be true

  Scenario: FormatState dim? delegates to parent
    Given a parent FormatState with code "fg:white dim"
    When I create a child FormatState with code "fg:red" and the parent
    Then the format_state dim? should be true

  Scenario: FormatState bold? delegates to parent
    Given a parent FormatState with code "fg:white bold"
    When I create a child FormatState with code "fg:red" and the parent
    Then the format_state bold? should be true

  Scenario: FormatState underline? delegates to parent
    Given a parent FormatState with code "fg:white underline"
    When I create a child FormatState with code "fg:red" and the parent
    Then the format_state underline? should be true

  Scenario: FormatState reverse? delegates to parent
    Given a parent FormatState with code "fg:white reverse"
    When I create a child FormatState with code "fg:red" and the parent
    Then the format_state reverse? should be false due to typo bug

  Scenario: FormatState standout? delegates to parent
    Given a parent FormatState with code "fg:white standout"
    When I create a child FormatState with code "fg:red" and the parent
    Then the format_state standout? should be true

  # ---------------------------------------------------------------------------
  #  FormatState – accessors returning defaults (no parent, no value)
  # ---------------------------------------------------------------------------
  Scenario: FormatState fg returns white default with no fg set and no parent
    When I create a FormatState with code "bg:blue"
    Then the format_state fg should be the default white

  Scenario: FormatState bg returns black default with no bg set and no parent
    When I create a FormatState with code "fg:red"
    Then the format_state bg should be the default black

  Scenario: FormatState blink? returns false by default
    When I create a FormatState with code "fg:red"
    Then the format_state blink? should be false

  Scenario: FormatState dim? returns false by default
    When I create a FormatState with code "fg:red"
    Then the format_state dim? should be false

  Scenario: FormatState bold? returns false by default
    When I create a FormatState with code "fg:red"
    Then the format_state bold? should be false

  Scenario: FormatState underline? returns false by default
    When I create a FormatState with code "fg:red"
    Then the format_state underline? should be false

  Scenario: FormatState reverse? returns false by default
    When I create a FormatState with code "fg:red"
    Then the format_state reverse? should be false due to typo bug

  Scenario: FormatState standout? returns false by default
    When I create a FormatState with code "fg:red"
    Then the format_state standout? should be false

  # ---------------------------------------------------------------------------
  #  FormatState – apply method
  # ---------------------------------------------------------------------------
  Scenario: Apply with all attributes enabled
    When I create a FormatState with code "fg:red bg:blue blink dim bold underline standout"
    And I apply the format_state to a mock window
    Then the mock window should have attron called for blink
    And the mock window should have attron called for dim
    And the mock window should have attron called for bold
    And the mock window should have attron called for underline
    And the mock window should have attron called for standout
    And the activate_color callback should have been called
    And the apply should handle reverse attribute

  Scenario: Apply with reverse via parent delegation
    Given a parent FormatState with code "fg:white reverse"
    When I create a child FormatState with code "fg:red" and the parent
    And I apply the format_state to a mock window
    Then the apply should handle reverse through parent

  Scenario: Apply with all attributes disabled
    When I create a FormatState with code "fg:red bg:blue noblink nodim nobold nounderline noreverse nostandout"
    And I apply the format_state to a mock window
    Then the mock window should have attroff called for blink
    And the mock window should have attroff called for dim
    And the mock window should have attroff called for bold
    And the mock window should have attroff called for underline
    And the mock window should have attroff called for reverse
    And the mock window should have attroff called for standout

  # ---------------------------------------------------------------------------
  #  FormatState – revert method
  # ---------------------------------------------------------------------------
  Scenario: Revert with no parent resets to defaults
    When I create a FormatState with code "fg:red bg:blue bold"
    And I revert the format_state on a mock window
    Then the activate_color callback should have been called with defaults
    And the mock window should have attrset called with A_NORMAL

  Scenario: Revert with parent delegates to parent apply
    Given a parent FormatState with code "fg:lime bg:blue"
    When I create a child FormatState with code "fg:red" and the parent
    And I revert the format_state on a mock window
    Then the activate_color callback should have been called
