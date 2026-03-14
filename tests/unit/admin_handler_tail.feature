Feature: AdminHandler#tail method
  In order to ensure the admin tail utility works correctly
  As a maintainer of the Aethyr engine
  I want the AdminHandler#tail method to read trailing lines from a file.

  Background:
    Given the tail test harness is ready

  Scenario: tail returns the last lines of a file with default count
    Given a temporary file with 15 lines of content
    When the admin handler tails the file with default arguments
    Then the tail output should contain 10 content lines
    And the tail output should end with a lines-shown summary

  Scenario: tail returns only the requested number of lines
    Given a temporary file with 15 lines of content
    When the admin handler tails the file requesting 5 lines
    Then the tail output should contain 5 content lines
    And the tail output should end with a lines-shown summary

  Scenario: tail handles a file with fewer lines than requested
    Given a temporary file with 3 lines of content
    When the admin handler tails the file with default arguments
    Then the tail output should contain 3 content lines
    And the tail output should end with a lines-shown summary
