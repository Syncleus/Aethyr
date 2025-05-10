Feature: HelpEntry construction invariants and behaviour
  Help entries are the bed-rock of the in-game documentation
  system and must obey strict construction rules.

  Scenario: Content-based help entry is NOT a redirect
    Given I create a content help entry with:
      | topic        | ruby      |
      | content      | Ruby docs |
      | syntax       | Rb        |
    Then the help entry should NOT be a redirect

  Scenario: Redirect help entry is flagged as a redirect
    Given I create a redirect help entry from "rspec" to "spec"
    Then the help entry should be a redirect to "spec"

  Scenario: Omitting syntax formats while providing content raises
    When I attempt to create a help entry with:
      | topic   | bad      |
      | content | oops     |
    Then the help-entry creation should raise RuntimeError with message "syntax_format must be defined"
