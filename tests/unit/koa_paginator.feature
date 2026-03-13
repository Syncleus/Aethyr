Feature: KPaginator
  The KPaginator wraps the Paginator class to provide easy
  paging of multi-line messages shown to game players.

  Background:
    Given I require the koa_paginator library

  # --- Multi-page content ---------------------------------------------------

  Scenario: Paging through multi-page content shows MORE prompt
    Given a kpag player with page height 3
    And a kpag message with 7 lines
    When I create a kpag paginator
    Then kpag pages should be 3
    And kpag lines should be 7
    And kpag current should be 0
    When I call kpag more
    Then kpag more? should be true
    And the kpag result should contain "---Type MORE for next page (1/3)---"
    And the kpag result should contain "Line 1"
    When I call kpag more
    Then kpag more? should be true
    And the kpag result should contain "---Type MORE for next page (2/3)---"
    When I call kpag more
    Then kpag more? should be false
    And the kpag result should not contain "---Type MORE"
    And the kpag result should end with a newline
    And kpag current should be 3

  # --- Past the end ---------------------------------------------------------

  Scenario: Calling more past the last page returns no-more message
    Given a kpag player with page height 3
    And a kpag message with 7 lines
    When I create a kpag paginator
    And I call kpag more
    And I call kpag more
    And I call kpag more
    And I call kpag more
    Then the kpag result should be the no-more message

  # --- Single page content --------------------------------------------------

  Scenario: Single-page content has no MORE prompt
    Given a kpag player with page height 5
    And a kpag message with 3 lines
    When I create a kpag paginator
    Then kpag pages should be 1
    And kpag lines should be 3
    When I call kpag more
    Then kpag more? should be false
    And the kpag result should not contain "---Type MORE"
    And the kpag result should end with a newline
    And kpag current should be 1
    When I call kpag more
    Then the kpag result should be the no-more message

  # --- Accessors ------------------------------------------------------------

  Scenario: Accessors return correct values after initialization
    Given a kpag player with page height 4
    And a kpag message with 10 lines
    When I create a kpag paginator
    Then kpag current should be 0
    And kpag lines should be 10
    And kpag pages should be 3
    And kpag more? should be true
