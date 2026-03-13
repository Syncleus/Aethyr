Feature: AteachCommand action
  In order to let admins teach skills to game objects
  As a maintainer of the Aethyr engine
  I want AteachCommand#action to find the target and delegate to alearn or reject invalid input.

  Background:
    Given a stubbed AteachCommand environment

  # --- initialize (line 9) + object not found (lines 15-20)
  Scenario: Teaching when target is not found outputs an error
    Given the ateach target is "nonexistent"
    And ateach find_object returns nil
    When the AteachCommand action is invoked
    Then the ateach player should see "Teach who what where?"

  # --- initialize (line 9) + valid target (lines 15-17, 23)
  Scenario: Teaching when target is found calls alearn
    Given the ateach target is "student"
    And ateach find_object returns a valid object
    When the AteachCommand action is invoked
    Then ateach alearn should have been called
