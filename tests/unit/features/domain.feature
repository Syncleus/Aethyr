@domain_aggregates
Feature: Event Sourcing Domain Aggregate Roots
  In order to ensure domain models properly manage state through events
  As a developer of the Aethyr engine
  I want the domain aggregate roots to correctly apply and handle events

  # ---------------------------------------------------------------------------
  # GameObject aggregate root
  # ---------------------------------------------------------------------------
  Scenario: Creating a GameObject sets initial state via GameObjectCreated event
    When I create a domain GameObject with id "obj-1" name "Excalibur" generic "sword" and container "room-1"
    Then the domain GameObject name should be "Excalibur"
    And the domain GameObject generic should be "sword"
    And the domain GameObject container_id should be "room-1"
    And the domain GameObject attributes should be an empty hash
    And the domain GameObject should not be deleted
    And the domain GameObject should have 1 uncommitted event
    And the domain GameObject uncommitted event 1 should be a GameObjectCreated

  Scenario: Creating a GameObject without container_id defaults to nil
    When I create a domain GameObject with id "obj-2" name "Potion" generic "potion" and no container
    Then the domain GameObject container_id should be nil

  Scenario: Updating a single attribute on a GameObject
    Given a domain GameObject with id "obj-3" name "Shield" generic "shield" and container "room-2"
    When I update the domain GameObject attribute "defense" to "15"
    Then the domain GameObject attributes should include "defense" with value "15"
    And the domain GameObject should have 2 uncommitted events

  Scenario: Updating multiple attributes on a GameObject
    Given a domain GameObject with id "obj-4" name "Helm" generic "armor" and container "room-3"
    When I update the domain GameObject attributes with "weight" as "3" and "color" as "silver"
    Then the domain GameObject attributes should include "weight" with value "3"
    And the domain GameObject attributes should include "color" with value "silver"

  Scenario: Updating the container of a GameObject
    Given a domain GameObject with id "obj-5" name "Ring" generic "jewelry" and container "room-4"
    When I update the domain GameObject container to "player-1"
    Then the domain GameObject container_id should be "player-1"

  Scenario: Deleting a GameObject marks it as deleted
    Given a domain GameObject with id "obj-6" name "Scroll" generic "consumable" and container "room-5"
    When I delete the domain GameObject
    Then the domain GameObject should be deleted

  # ---------------------------------------------------------------------------
  # Player aggregate root
  # ---------------------------------------------------------------------------
  Scenario: Creating a Player sets player-specific state via PlayerCreated event
    When I create a domain Player with id "player-1" name "Gandalf" and password_hash "abc123hash"
    Then the domain Player password_hash should be "abc123hash"
    And the domain Player admin should be false
    And the domain Player should have 2 uncommitted events
    And the domain Player first uncommitted event should be a GameObjectCreated
    And the domain Player second uncommitted event should be a PlayerCreated

  Scenario: Setting a Player password updates the password hash
    Given a domain Player with id "player-2" name "Frodo" and password_hash "oldhash"
    When I set the domain Player password to "newhash"
    Then the domain Player password_hash should be "newhash"

  Scenario: Setting a Player admin status to true
    Given a domain Player with id "player-3" name "Aragorn" and password_hash "kinghash"
    When I set the domain Player admin to true
    Then the domain Player admin should be true

  Scenario: Setting a Player admin status to false
    Given a domain Player with id "player-4" name "Legolas" and password_hash "elfhash"
    When I set the domain Player admin to true
    And I set the domain Player admin to false
    Then the domain Player admin should be false

  # ---------------------------------------------------------------------------
  # Room aggregate root
  # ---------------------------------------------------------------------------
  Scenario: Creating a Room sets room-specific state via RoomCreated event
    When I create a domain Room with id "room-1" name "Forest Clearing" and description "A peaceful clearing in the forest."
    Then the domain Room description should be "A peaceful clearing in the forest."
    And the domain Room exits should be an empty hash
    And the domain Room should have 2 uncommitted events
    And the domain Room first uncommitted event should be a GameObjectCreated
    And the domain Room second uncommitted event should be a RoomCreated

  Scenario: Updating a Room description
    Given a domain Room with id "room-2" name "Cave Entrance" and description "A dark cave entrance."
    When I update the domain Room description to "A sunlit cave entrance covered in vines."
    Then the domain Room description should be "A sunlit cave entrance covered in vines."

  Scenario: Adding an exit to a Room
    Given a domain Room with id "room-3" name "Hallway" and description "A long hallway."
    When I add a domain Room exit "north" to "room-10"
    Then the domain Room exits should include "north" pointing to "room-10"

  Scenario: Adding multiple exits to a Room
    Given a domain Room with id "room-4" name "Crossroads" and description "A crossroads."
    When I add a domain Room exit "north" to "room-11"
    And I add a domain Room exit "south" to "room-12"
    Then the domain Room exits should include "north" pointing to "room-11"
    And the domain Room exits should include "south" pointing to "room-12"

  Scenario: Removing an exit from a Room
    Given a domain Room with id "room-5" name "Tower" and description "A tall tower."
    And I add a domain Room exit "east" to "room-13"
    When I remove the domain Room exit "east"
    Then the domain Room exits should not include "east"

  Scenario: Removing one exit preserves other exits
    Given a domain Room with id "room-6" name "Garden" and description "A lush garden."
    And I add a domain Room exit "north" to "room-14"
    And I add a domain Room exit "south" to "room-15"
    When I remove the domain Room exit "north"
    Then the domain Room exits should not include "north"
    And the domain Room exits should include "south" pointing to "room-15"
