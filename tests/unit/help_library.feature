Feature: HelpLibrary manages in-game help entries
  The HelpLibrary is the central registry for looking up,
  searching, and rendering help topics in the MUD.

  Background:
    Given I require the help library

  # --- Registration and lookup ------------------------------------------------

  Scenario: Registering an entry and looking it up by topic
    Given a help entry mock with topic "move"
    When I register the help entry in the library
    Then looking up topic "move" should return that entry

  Scenario: Deregistering an entry removes it
    Given a help entry mock with topic "look"
    When I register the help entry in the library
    And I deregister the topic "look"
    Then looking up topic "look" should return nil

  # --- Search and listing -----------------------------------------------------

  Scenario: search_topics finds matching topics
    Given help entry mocks with topics "combat", "communicate", "craft"
    When I register all the help entries in the library
    Then searching for "com" should return "combat" and "communicate"

  Scenario: topics returns all registered topic keys
    Given help entry mocks with topics "alpha", "beta", "gamma"
    When I register all the help entries in the library
    Then the library topics should contain "alpha", "beta", and "gamma"

  # --- render_topic -----------------------------------------------------------

  Scenario: render_topic for a missing topic returns not-found message
    Then rendering topic "nonexistent" should return the not-found message

  Scenario: render_topic for a basic entry with syntax and content
    Given a renderable entry "sword" with content "Sword help" syntax "sword <target>" and no aliases or see_also
    When I register the help entry in the library
    Then rendering topic "sword" should include "Syntax: sword <target>"
    And rendering topic "sword" should include "Sword help"
    And rendering topic "sword" should not include "Aliases:"
    And rendering topic "sword" should not include "See also:"
    And rendering topic "sword" should not include "redirected from"

  Scenario: render_topic follows a redirect chain
    Given a redirect entry "go" that redirects to "move"
    And a renderable entry "move" with content "Move help" syntax "move <dir>" and no aliases or see_also
    When I register all the help entries in the library
    Then rendering topic "go" should include "redirected from go"
    And rendering topic "go" should include "Move help"

  Scenario: render_topic shows aliases when present
    Given a renderable entry "look" with content "Look help" syntax "look [thing]" aliases "l", "glance" and no see_also
    When I register the help entry in the library
    Then rendering topic "look" should include "Aliases: l, glance"

  Scenario: render_topic shows see_also when present
    Given a renderable entry "attack" with content "Attack help" syntax "attack <target>" no aliases and see_also "defend", "flee"
    When I register the help entry in the library
    Then rendering topic "attack" should include "See also: defend, flee"
