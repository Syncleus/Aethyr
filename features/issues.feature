Feature: Issue registry lifecycle assurance

  Background:
    Given a clean issue store for type "bug"

  Scenario: Add and retrieve an issue
    When I add an issue of type "bug" reported by "Alice" with report "Broken link on homepage"
    Then the last issue should have id "1"
    And retrieving issue "1" of type "bug" should return a report "Broken link on homepage"
    And listing issues of type "bug" should include reporter "Alice"

  Scenario: Deny access to non-owner non-admin
    Given I add an issue of type "bug" reported by "Alice" with report "Broken link on homepage"
    When player "Charlie" who is not admin tries to access issue "1" of type "bug"
    Then the access result should be "You cannot access that bug."

  Scenario: Allow admin access
    Given I add an issue of type "bug" reported by "Alice" with report "Broken link on homepage"
    When admin player "Dave" tries to access issue "1" of type "bug"
    Then the access result should be nil

  Scenario: Show issue details with no comments
    Given I add an issue of type "bug" reported by "Alice" with report "Broken link on homepage"
    When I show issue "1" of type "bug"
    Then the show result should include "Reported by Alice"
    And the show result should include "Status: new"

  Scenario: Append comment and show with comment
    Given I add an issue of type "bug" reported by "Alice" with report "Broken link on homepage"
    When I append comment "I can confirm" by "Bob" to issue "1" of type "bug"
    And I show issue "1" of type "bug"
    Then the show result should include "I can confirm"

  Scenario: Set status and get status
    Given I add an issue of type "bug" reported by "Alice" with report "Broken link on homepage"
    When I set status "resolved" by "Bob" on issue "1" of type "bug"
    Then retrieving status of issue "1" of type "bug" should be "resolved"

  Scenario: Delete issue
    Given I add an issue of type "bug" reported by "Alice" with report "Broken link on homepage"
    When I delete issue "1" of type "bug"
    Then listing issues of type "bug" should be empty

  Scenario: List issues filtered by reporter
    Given I add an issue of type "bug" reported by "Alice" with report "Broken link on homepage"
    And I add an issue of type "bug" reported by "Bob" with report "Button misaligned"
    When I list issues of type "bug" for reporter "Alice"
    Then the filtered list should include "Alice"
    And the filtered list should not include "Bob" 