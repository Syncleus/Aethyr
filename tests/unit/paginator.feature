Feature: Paginator
  The Paginator class splits a collection into pages and provides
  navigation metadata (next/prev, item numbers, enumeration, etc.).

  Background:
    Given I require the paginator library

  # --- Constructor validation ------------------------------------------------

  Scenario: Creating a Paginator without a block raises MissingSelectError
    Then creating a Paginator without a block should raise MissingSelectError

  # --- first / last ----------------------------------------------------------

  Scenario: first returns the first page
    Given a paginator with 10 items and 3 per page
    When I get the first page
    Then the page number should be 1

  Scenario: last returns the last page
    Given a paginator with 10 items and 3 per page
    When I get the last page
    Then the page number should be 4

  # --- each (Enumerable) ----------------------------------------------------

  Scenario: each iterates over all pages
    Given a paginator with 10 items and 3 per page
    When I iterate over all pages
    Then I should have visited 4 pages
    And the visited page numbers should be "1,2,3,4"

  # --- Page#empty? -----------------------------------------------------------

  Scenario: A page with items is not empty
    Given a paginator with 10 items and 3 per page
    When I get page 1
    Then the page should not be empty

  Scenario: A page from a zero-count paginator is empty
    Given a paginator with 0 items and 5 per page
    When I get page 1
    Then the page should be empty

  # --- Page#prev? / Page#prev ------------------------------------------------

  Scenario: First page has no previous page
    Given a paginator with 10 items and 3 per page
    When I get page 1
    Then prev? should be false
    And prev should be nil

  Scenario: Second page has a previous page
    Given a paginator with 10 items and 3 per page
    When I get page 2
    Then prev? should be true
    And prev should be page 1

  # --- Page#next? / Page#next ------------------------------------------------

  Scenario: Last page has no next page
    Given a paginator with 10 items and 3 per page
    When I get page 4
    Then next? should be false
    And next should be nil

  Scenario: First page has a next page
    Given a paginator with 10 items and 3 per page
    When I get page 1
    Then next? should be true
    And next should be page 2

  # --- Page#first_item_number ------------------------------------------------

  Scenario: first_item_number on page 1
    Given a paginator with 10 items and 3 per page
    When I get page 1
    Then first_item_number should be 1

  Scenario: first_item_number on page 3
    Given a paginator with 10 items and 3 per page
    When I get page 3
    Then first_item_number should be 7

  # --- Page#last_item_number -------------------------------------------------

  Scenario: last_item_number on a middle page (has next)
    Given a paginator with 10 items and 3 per page
    When I get page 2
    Then last_item_number should be 6

  Scenario: last_item_number on the last page (no next)
    Given a paginator with 10 items and 3 per page
    When I get page 4
    Then last_item_number should be 10

  # --- Page#== ---------------------------------------------------------------

  Scenario: Two pages with the same number from the same paginator are equal
    Given a paginator with 10 items and 3 per page
    When I get page 2
    And I also get page 2
    Then the two pages should be equal

  Scenario: Two pages with different numbers are not equal
    Given a paginator with 10 items and 3 per page
    When I get page 1
    And I also get page 2
    Then the two pages should not be equal

  # --- Page#each -------------------------------------------------------------

  Scenario: Page each iterates over items on that page
    Given a paginator with 10 items and 3 per page
    When I get page 1
    Then iterating the page should yield 3 items

  Scenario: Page each on the last partial page
    Given a paginator with 10 items and 3 per page
    When I get page 4
    Then iterating the page should yield 1 items

  # --- Page#method_missing (delegation) --------------------------------------

  Scenario: Page delegates unknown methods to the pager
    Given a paginator with 10 items and 3 per page
    When I get page 1
    Then calling per_page on the page should return 3
    And calling number_of_pages on the page should return 4

  Scenario: Page raises NoMethodError for truly unknown methods
    Given a paginator with 10 items and 3 per page
    When I get page 1
    Then calling a nonexistent method on the page should raise NoMethodError

  # --- Block arity -----------------------------------------------------------

  Scenario: Paginator passes only offset when block arity is 1
    Given a paginator with 5 items and 2 per page using arity-1 block
    When I get page 2
    Then the page items should be "item3,item4"

  Scenario: Paginator passes offset and per_page when block arity is 2
    Given a paginator with 5 items and 2 per page using arity-2 block
    When I get page 2
    Then the page items should be "item3,item4"
