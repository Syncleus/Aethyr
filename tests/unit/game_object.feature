Feature: GameObject base class behaviour
  GameObject is the base class for all game objects in Aethyr.
  It provides identity, description, movement messages, equality,
  flags, attributes, and default gender handling.

  # ── Gender defaults ───────────────────────────────────────────────
  Scenario: Gender defaults to masculine when sex is male
    Given a base GameObject with sex "m"
    Then the game object gender should be masculine

  Scenario: Gender defaults to feminine when sex is female
    Given a base GameObject with sex "f"
    Then the game object gender should be feminine

  Scenario: Gender defaults to neuter when sex is neuter
    Given a base GameObject with sex "n"
    Then the game object gender should be neuter

  # ── detach_attribute ──────────────────────────────────────────────
  Scenario: Detach attribute by Class
    Given a base GameObject with defaults
    And I attach a test attribute instance to the game object
    When I detach the attribute by its class
    Then the game object should have no attributes

  Scenario: Detach attribute by matching instance
    Given a base GameObject with defaults
    And I attach a test attribute instance to the game object
    When I detach the attribute by its matching instance
    Then the game object should have no attributes

  Scenario: Detach attribute by non-matching instance does nothing
    Given a base GameObject with defaults
    And I attach a test attribute instance to the game object
    When I detach the attribute by a non-matching instance
    Then the game object should still have one attribute

  # ── flags and add_flag ────────────────────────────────────────────
  Scenario: Flags returns a hash
    Given a base GameObject with defaults
    Then the game object flags should be a Hash

  Scenario: Add a flag to the game object
    Given a base GameObject with defaults
    When I add a test flag with id 42 to the game object
    Then the game object info flags should contain id 42

  # ── update / busy? ───────────────────────────────────────────────
  Scenario: Update returns early when busy
    Given a base GameObject with defaults
    And the game object is marked busy
    When I call update on the game object
    Then the game object should still be busy

  Scenario: Update runs and resets busy when not busy
    Given a base GameObject with defaults
    Then the game object should not be busy
    When I call update on the game object
    Then the game object should not be busy

  Scenario: Update with Reacts mixin triggers alert tick
    Given a base GameObject that includes Reacts
    When I call update on the reacting game object
    Then the reacting game object should not be busy

  # ── busy? ─────────────────────────────────────────────────────────
  Scenario: busy? returns false by default
    Given a base GameObject with defaults
    Then the game object should not be busy

  # ── plural ────────────────────────────────────────────────────────
  Scenario: Plural returns explicit plural when set
    Given a base GameObject with defaults
    And the game object plural is set to "widgets"
    Then the game object plural should be "widgets"

  Scenario: Plural falls back to generic when available
    Given a base GameObject with generic "spoon"
    Then the game object plural should be "spoons"

  Scenario: Plural falls back to name when generic is nil
    Given a base GameObject with name "fork" and nil generic
    Then the game object plural should be "s"

  Scenario: Plural falls back to unknowns when nothing is set
    Given a base GameObject with no name and no generic
    Then the game object plural should be "unkowns"

  # ── alert (no-op) ────────────────────────────────────────────────
  Scenario: Alert is a no-op on base GameObject
    Given a base GameObject with defaults
    When I call alert on the game object
    Then the game object alert should not raise an error

  # ── method_missing ───────────────────────────────────────────────
  Scenario: Method missing returns nil and logs
    Given a base GameObject with defaults
    When I call an undefined method on the game object
    Then the result should be nil

  # ── == operator ──────────────────────────────────────────────────
  Scenario: Equality with nil returns false
    Given a base GameObject with defaults
    Then the game object should not equal nil

  Scenario: Equality with matching goid returns true
    Given a base GameObject with defaults
    Then the game object should equal its own goid

  Scenario: Equality with matching name (case-insensitive) returns true
    Given a base GameObject with name "Sword"
    Then the game object should equal "sword"

  Scenario: Equality with matching alt_name returns true
    Given a base GameObject with name "Sword" and alt_name "blade"
    Then the game object should equal alt name "blade"

  Scenario: Equality with matching class returns true
    Given a base GameObject with defaults
    Then the game object should equal its own class

  Scenario: Equality with non-matching value returns false
    Given a base GameObject with defaults
    Then the game object should not equal "zzz_no_match_zzz"

  # ── long_desc= ───────────────────────────────────────────────────
  Scenario: Setting long_desc stores the value
    Given a base GameObject with defaults
    When I set the game object long_desc to "A shiny sword."
    Then the game object long_desc should be "A shiny sword."

  Scenario: Setting long_desc with event sourcing enabled
    Given a base GameObject with defaults
    And game object event sourcing is enabled
    When I set the game object long_desc to "An old shield."
    Then the game object long_desc should be "An old shield."

  # ── container= ───────────────────────────────────────────────────
  Scenario: Setting container stores the value
    Given a base GameObject with defaults
    When I set the game object container to "room_42"
    Then the game object container should be "room_42"

  Scenario: Setting container with event sourcing enabled
    Given a base GameObject with defaults
    And game object event sourcing is enabled
    When I set the game object container to "room_99"
    Then the game object container should be "room_99"

  # ── update_attributes ────────────────────────────────────────────
  Scenario: Updating attributes stores values
    Given a base GameObject with defaults
    When I update attributes with name "Axe" and movable true
    Then the game object name should be "Axe"
    And the game object should be movable

  Scenario: Updating attributes with event sourcing enabled
    Given a base GameObject with defaults
    And game object event sourcing is enabled
    When I update attributes with name "Mace" and movable true
    Then the game object name should be "Mace"

  # ── long_desc getter ─────────────────────────────────────────────
  Scenario: long_desc returns short_desc when long_desc is empty
    Given a base GameObject with empty long_desc
    Then the game object long_desc should be the short_desc

  Scenario: long_desc returns long_desc when set
    Given a base GameObject with long_desc "Detailed description."
    Then the game object long_desc should be "Detailed description."

  # ── can_move? ────────────────────────────────────────────────────
  Scenario: can_move? returns false by default
    Given a base GameObject with defaults
    Then the game object should not be movable

  # ── entrance_message ─────────────────────────────────────────────
  Scenario: Entrance message from up
    Given a base GameObject with name "Goblin"
    Then the entrance message from "up" should be "Goblin enters from up above."

  Scenario: Entrance message from down
    Given a base GameObject with name "Goblin"
    Then the entrance message from "down" should be "Goblin enters from below."

  Scenario: Entrance message from in
    Given a base GameObject with name "Goblin"
    Then the entrance message from "in" should be "Goblin enters from inside."

  Scenario: Entrance message from out
    Given a base GameObject with name "Goblin"
    Then the entrance message from "out" should be "Goblin enters from outside."

  Scenario: Entrance message from other direction
    Given a base GameObject with name "Goblin"
    Then the entrance message from "west" should be "Goblin enters from the west."

  Scenario: Entrance message with custom message
    Given a base GameObject with name "Bird" and generic "large bird"
    And the game object has a custom entrance message "!name flies in from !direction."
    Then the entrance message from "west" should be "Bird flies in from the west."

  # ── exit_message ─────────────────────────────────────────────────
  Scenario: Exit message going up
    Given a base GameObject with name "Goblin"
    Then the exit message to "up" should be "Goblin leaves to go up."

  Scenario: Exit message going down
    Given a base GameObject with name "Goblin"
    Then the exit message to "down" should be "Goblin leaves to go down."

  Scenario: Exit message going in
    Given a base GameObject with name "Goblin"
    Then the exit message to "in" should be "Goblin leaves to go inside."

  Scenario: Exit message going out
    Given a base GameObject with name "Goblin"
    Then the exit message to "out" should be "Goblin leaves to go outside."

  Scenario: Exit message going other direction
    Given a base GameObject with name "Goblin"
    Then the exit message to "east" should be "Goblin leaves to the east."

  Scenario: Exit message with custom message
    Given a base GameObject with name "Bird" and generic "large bird"
    And the game object has a custom exit message "!name flies away to !direction."
    Then the exit message to "east" should be "Bird flies away to the east."

  # ── name ─────────────────────────────────────────────────────────
  Scenario: Name returns article + generic when name is empty
    Given a base GameObject with empty name and generic "spoon" and article "a"
    Then the game object name should be "a spoon"

  Scenario: Name returns name when set
    Given a base GameObject with name "Excalibur"
    Then the game object name should be "Excalibur"
