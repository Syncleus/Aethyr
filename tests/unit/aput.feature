Feature: AputCommand action
  In order to let admins move game objects between containers
  As a maintainer of the Aethyr engine
  I want AputCommand#action to correctly move objects into containers.

  Background:
    Given a stubbed AputCommand environment

  # --- Lines 9, 15-18: object is a GameObject instance -----------------------
  Scenario: Moving a GameObject instance directly into a generic container
    Given the aput object is a GameObject instance
    And the aput container reference is "chest1"
    And the aput container is a generic object
    When the AputCommand action is invoked
    Then the aput player should see "Moved"

  # --- Lines 20-21: object reference is "here" --------------------------------
  Scenario: Using "here" as the object reference resolves to player container
    Given the aput object reference is "here"
    And the aput container reference is "chest1"
    And the aput container is a generic object
    When the AputCommand action is invoked
    Then the aput player should see "Moved"

  # --- Lines 26-28: object not found (nil) ------------------------------------
  Scenario: Object not found produces an error message
    Given the aput object reference is "nonexistent"
    And the aput container reference is "chest1"
    And aput find_object returns nil for the object
    When the AputCommand action is invoked
    Then the aput player should see "Cannot find"
    And the aput player should see "to move"

  # --- Lines 29-34: container is "!world" with existing container -------------
  Scenario: Putting object in !world removes it from its current container
    Given the aput object reference is "gem1"
    And the aput container reference is "!world"
    And the aput object has an existing container
    When the AputCommand action is invoked
    Then the aput player should see "Removed"
    And the aput player should see "from any containers"

  # --- Lines 29-34: container is "!world" without container -------------------
  Scenario: Putting object in !world when container is nil
    Given the aput object reference is "gem1"
    And the aput container reference is "!world"
    And the aput object has no existing container
    When the AputCommand action is invoked
    Then the aput player should see "Removed"
    And the aput player should see "from any containers"

  # --- Lines 35-36, 38-39: container is "here" but room not found ------------
  Scenario: Container "here" when room not found produces error
    Given the aput object reference is "gem1"
    And the aput container reference is "here"
    And aput manager find returns nil for here
    When the AputCommand action is invoked
    Then the aput player should see "Cannot find"

  # --- Lines 35-36: container is "here" successfully --------------------------
  Scenario: Container "here" resolves to the player room
    Given the aput object reference is "gem1"
    And the aput container reference is "here"
    And aput manager find returns the room for here
    And the aput object has an existing container
    When the AputCommand action is invoked
    Then the aput player should see "Moved"

  # --- Lines 41-43: container nil (general case) ------------------------------
  Scenario: Container not found produces an error message
    Given the aput object reference is "gem1"
    And the aput container reference is "nonexistent_container"
    And aput find_object returns nil for the container
    When the AputCommand action is invoked
    Then the aput player should see "Cannot find"

  # --- Lines 46-48: object has existing container, removing it ----------------
  Scenario: Object with existing container is removed from old container first
    Given the aput object reference is "gem1"
    And the aput container reference is "chest1"
    And the aput object has an existing container
    And the aput container is a generic object
    When the AputCommand action is invoked
    Then the aput player should see "Moved"
    And the aput object should have been removed from old container

  # --- Lines 46-48: object with nil container skips removal -------------------
  Scenario: Object with nil container skips removal step
    Given the aput object reference is "gem1"
    And the aput container reference is "chest1"
    And the aput object has no existing container
    And the aput container is a generic object
    When the AputCommand action is invoked
    Then the aput player should see "Moved"

  # --- Lines 51-52: position with :at parameter -------------------------------
  Scenario: Providing a position via the at parameter
    Given the aput object reference is "gem1"
    And the aput container reference is "chest1"
    And the aput container is a generic object
    And the aput at parameter is "3x5"
    When the AputCommand action is invoked
    Then the aput player should see "at 3x5"

  # --- Lines 55-56: container is an Inventory ---------------------------------
  Scenario: Moving object into an Inventory container
    Given the aput object reference is "gem1"
    And the aput container reference is "inv1"
    And the aput container is an Inventory
    When the AputCommand action is invoked
    Then the aput player should see "Moved"

  # --- Lines 57-58: container is a Container ----------------------------------
  Scenario: Moving object into a Container
    Given the aput object reference is "gem1"
    And the aput container reference is "box1"
    And the aput container is a Container
    When the AputCommand action is invoked
    Then the aput player should see "Moved"

  # --- Lines 60-61: container is generic (has inventory method) ---------------
  Scenario: Moving object into a generic object with inventory
    Given the aput object reference is "gem1"
    And the aput container reference is "room1"
    And the aput container is a generic object
    When the AputCommand action is invoked
    Then the aput player should see "Moved"
    And the aput object container should be set to the generic container goid

  # --- Line 64: success output with no position --------------------------------
  Scenario: Success output without position
    Given the aput object reference is "gem1"
    And the aput container reference is "chest1"
    And the aput container is a generic object
    When the AputCommand action is invoked
    Then the aput player should see "Moved"
    And the aput player should not see "at "

  # --- Line 64: success output with position -----------------------------------
  Scenario: Success output with position
    Given the aput object reference is "gem1"
    And the aput container reference is "chest1"
    And the aput container is a generic object
    And the aput at parameter is "2x4"
    When the AputCommand action is invoked
    Then the aput player should see "Moved"
    And the aput player should see "at 2x4"

  # --- Lines 55-56: Inventory container with position --------------------------
  Scenario: Moving object into Inventory with position
    Given the aput object reference is "gem1"
    And the aput container reference is "inv1"
    And the aput container is an Inventory
    And the aput at parameter is "1x2"
    When the AputCommand action is invoked
    Then the aput player should see "Moved"
    And the aput player should see "at 1x2"
