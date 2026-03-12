Feature: Equipment object
  The Equipment class manages worn and wielded items for a player,
  tracking positions, layers, and providing display output.

  # ── initialisation ──────────────────────────────────────────────
  Scenario: Equipment initialises with empty equipment hash
    Given I require the Equipment library
    When I create a new Equipment object with player goid "player1"
    Then the equipment hash should be empty
    And the equipment goid should be "player1"
    And the equipment string representation should include "player1"

  # ── worn_or_wielded? ────────────────────────────────────────────
  Scenario: worn_or_wielded? returns false when item not in inventory
    Given I require the Equipment library
    And I create a new Equipment object with player goid "player1"
    When I check worn_or_wielded for an item not in inventory
    Then worn_or_wielded should return false

  Scenario: worn_or_wielded? returns remove message for worn item
    Given I require the Equipment library
    And I create a new Equipment object with player goid "player1"
    And I create a wearable item named "helmet" at position "head" layer 0
    And I wear the item "helmet" on the equipment
    When I check worn_or_wielded for item "helmet"
    Then worn_or_wielded should return a remove message for "helmet"

  Scenario: worn_or_wielded? returns unwield message for wielded item
    Given I require the Equipment library
    And I create a new Equipment object with player goid "player1"
    And I create a weapon item named "sword" at position "wield" layer 0
    And I wear the item "sword" on the equipment
    When I check worn_or_wielded for item "sword"
    Then worn_or_wielded should return an unwield message for "sword"

  # ── get_wielded ─────────────────────────────────────────────────
  Scenario: get_wielded returns nil when nothing is wielded
    Given I require the Equipment library
    And I create a new Equipment object with player goid "player1"
    Then get_wielded with no argument should return nil

  Scenario: get_wielded returns left-wielded item
    Given I require the Equipment library
    And I create a new Equipment object with player goid "player1"
    And I create a weapon item named "left sword" at position "left_wield" layer 0
    And I wear the item "left sword" on the equipment
    Then get_wielded with "left" should return item "left sword"

  Scenario: get_wielded returns right-wielded item
    Given I require the Equipment library
    And I create a new Equipment object with player goid "player1"
    And I create a weapon item named "right sword" at position "right_wield" layer 0
    And I wear the item "right sword" on the equipment
    Then get_wielded with "right" should return item "right sword"

  Scenario: get_wielded returns dual-wielded item
    Given I require the Equipment library
    And I create a new Equipment object with player goid "player1"
    And I create a weapon item named "greatsword" at position "dual_wield" layer 0
    And I wear the item "greatsword" on the equipment
    Then get_wielded with "dual" should return item "greatsword"

  Scenario: get_wielded with unknown hand falls back to any wielded
    Given I require the Equipment library
    And I create a new Equipment object with player goid "player1"
    And I create a weapon item named "fallback sword" at position "left_wield" layer 0
    And I wear the item "fallback sword" on the equipment
    Then get_wielded with "unknown" should return item "fallback sword"

  Scenario: get_wielded with no argument finds first wielded
    Given I require the Equipment library
    And I create a new Equipment object with player goid "player1"
    And I create a weapon item named "any sword" at position "right_wield" layer 0
    And I wear the item "any sword" on the equipment
    Then get_wielded with no argument should return item "any sword"

  Scenario: get_wielded returns nil for specific empty hand
    Given I require the Equipment library
    And I create a new Equipment object with player goid "player1"
    Then get_wielded with "left" should return nil

  # ── get_all_wielded ─────────────────────────────────────────────
  Scenario: get_all_wielded returns all wielded items
    Given I require the Equipment library
    And I create a new Equipment object with player goid "player1"
    And I create a weapon item named "left blade" at position "left_wield" layer 0
    And I create a weapon item named "right blade" at position "right_wield" layer 0
    And I wear the item "left blade" on the equipment
    And I wear the item "right blade" on the equipment
    Then get_all_wielded should return 2 items

  Scenario: get_all_wielded returns empty array when nothing wielded
    Given I require the Equipment library
    And I create a new Equipment object with player goid "player1"
    Then get_all_wielded should return 0 items

  # ── check_wield ─────────────────────────────────────────────────
  Scenario: check_wield returns nil when hand is free
    Given I require the Equipment library
    And I create a new Equipment object with player goid "player1"
    And I create a weapon item named "new sword" at position "left_wield" layer 0
    Then check_wield for item "new sword" should return nil

  Scenario: check_wield with explicit position string
    Given I require the Equipment library
    And I create a new Equipment object with player goid "player1"
    And I create a weapon item named "new sword" at position "wield" layer 0
    Then check_wield for item "new sword" with position "left_wield" should return nil

  Scenario: check_wield detects left hand already occupied
    Given I require the Equipment library
    And I create a new Equipment object with player goid "player1"
    And I create a weapon item named "old sword" at position "left_wield" layer 0
    And I wear the item "old sword" on the equipment
    And I create a weapon item named "new sword" at position "left_wield" layer 0
    Then check_wield for item "new sword" should return "You are already wielding something in that hand."

  Scenario: check_wield detects right hand already occupied
    Given I require the Equipment library
    And I create a new Equipment object with player goid "player1"
    And I create a weapon item named "old sword" at position "right_wield" layer 0
    And I wear the item "old sword" on the equipment
    And I create a weapon item named "new sword" at position "right_wield" layer 0
    Then check_wield for item "new sword" should return "You are already wielding something in that hand."

  Scenario: check_wield detects dual wield blocking left
    Given I require the Equipment library
    And I create a new Equipment object with player goid "player1"
    And I create a weapon item named "greatsword" at position "dual_wield" layer 0
    And I wear the item "greatsword" on the equipment
    And I create a weapon item named "dagger" at position "left_wield" layer 0
    Then check_wield for item "dagger" should return "You are wielding a two-handed weapon already."

  Scenario: check_wield detects dual wield blocking right
    Given I require the Equipment library
    And I create a new Equipment object with player goid "player1"
    And I create a weapon item named "greatsword" at position "dual_wield" layer 0
    And I wear the item "greatsword" on the equipment
    And I create a weapon item named "dagger" at position "right_wield" layer 0
    Then check_wield for item "dagger" should return "You are wielding a two-handed weapon already."

  Scenario: check_wield generic wield needs empty hand when both full
    Given I require the Equipment library
    And I create a new Equipment object with player goid "player1"
    And I create a weapon item named "sword1" at position "left_wield" layer 0
    And I create a weapon item named "sword2" at position "right_wield" layer 0
    And I wear the item "sword1" on the equipment
    And I wear the item "sword2" on the equipment
    And I create a weapon item named "sword3" at position "wield" layer 0
    Then check_wield for item "sword3" should return "You need an empty hand."

  Scenario: check_wield generic wield blocked by dual wield
    Given I require the Equipment library
    And I create a new Equipment object with player goid "player1"
    And I create a weapon item named "greatsword" at position "dual_wield" layer 0
    And I wear the item "greatsword" on the equipment
    And I create a weapon item named "dagger" at position "wield" layer 0
    Then check_wield for item "dagger" should return "You are wielding a two-handed weapon already."

  Scenario: check_wield dual_wield needs both hands empty
    Given I require the Equipment library
    And I create a new Equipment object with player goid "player1"
    And I create a weapon item named "sword1" at position "left_wield" layer 0
    And I wear the item "sword1" on the equipment
    And I create a weapon item named "greatsword" at position "dual_wield" layer 0
    Then check_wield for item "greatsword" should return "You need both hands to be empty."

  Scenario: check_wield returns nil for item with default position
    Given I require the Equipment library
    And I create a new Equipment object with player goid "player1"
    And I create a weapon item named "mysword" at position "wield" layer 0
    Then check_wield for item "mysword" should return nil

  # ── wear ────────────────────────────────────────────────────────
  Scenario: wear equips an item at its default position
    Given I require the Equipment library
    And I create a new Equipment object with player goid "player1"
    And I create a wearable item named "hat" at position "head" layer 0
    And I wear the item "hat" on the equipment
    Then the item "hat" should be in the equipment at position "head"

  Scenario: wear equips an item at an explicit position
    Given I require the Equipment library
    And I create a new Equipment object with player goid "player1"
    And I create a wearable item named "ring" at position "left_ring_finger" layer 0
    When I wear item "ring" with position "left_ring_finger" on equipment
    Then the item "ring" should be in the equipment at position "left_ring_finger"

  Scenario: wear returns nil when no position available
    Given I require the Equipment library
    And I create a new Equipment object with player goid "player1"
    And I create a wearable item named "hat1" at position "head" layer 0
    And I create a wearable item named "hat2" at position "head" layer 0
    And I wear the item "hat1" on the equipment
    When I try to wear item "hat2" on the equipment
    Then wear should return nil

  Scenario: wear removes item from non-player container
    Given I require the Equipment library
    And I create a new Equipment object with player goid "player1"
    And I create a wearable item named "shirt" at position "torso" layer 2 with container
    And I wear the item "shirt" on the equipment
    Then the item "shirt" should have nil container
    And the item "shirt" should have equipment_of set to "player1"

  Scenario: wear sets the item container to nil
    Given I require the Equipment library
    And I create a new Equipment object with player goid "player1"
    And I create a wearable item named "hat" at position "head" layer 0
    And I wear the item "hat" on the equipment
    Then the item "hat" should have nil container

  # ── remove ──────────────────────────────────────────────────────
  Scenario: remove takes off a worn item
    Given I require the Equipment library
    And I create a new Equipment object with player goid "player1"
    And I create a wearable item named "hat" at position "head" layer 0
    And I wear the item "hat" on the equipment
    And I remove item "hat" from the equipment
    Then remove should return true
    And the item "hat" should have container set to "player1"

  Scenario: remove returns false for item not equipped
    Given I require the Equipment library
    And I create a new Equipment object with player goid "player1"
    And I create a wearable item named "hat" at position "head" layer 0
    And I remove item "hat" from the equipment
    Then remove should return false

  # ── delete ──────────────────────────────────────────────────────
  Scenario: delete removes item by goid
    Given I require the Equipment library
    And I create a new Equipment object with player goid "player1"
    And I create a wearable item named "hat" at position "head" layer 0
    And I wear the item "hat" on the equipment
    And I delete item "hat" from the equipment by goid
    Then the equipment should not contain item "hat"

  Scenario: delete accepts a game object directly
    Given I require the Equipment library
    And I create a new Equipment object with player goid "player1"
    And I create a wearable item named "hat" at position "head" layer 0
    And I wear the item "hat" on the equipment
    And I delete game object "hat" from the equipment
    Then the equipment should not contain item "hat"

  # ── find ────────────────────────────────────────────────────────
  Scenario: find locates a worn item by name
    Given I require the Equipment library
    And I create a new Equipment object with player goid "player1"
    And I create a wearable item named "hat" at position "head" layer 0
    And I wear the item "hat" on the equipment
    Then find should locate item "hat"

  # ── position_of ─────────────────────────────────────────────────
  Scenario: position_of returns the position of a worn item
    Given I require the Equipment library
    And I create a new Equipment object with player goid "player1"
    And I create a wearable item named "hat" at position "head" layer 0
    And I wear the item "hat" on the equipment
    Then position_of should return "head" for item "hat"

  Scenario: position_of returns nil for unequipped item
    Given I require the Equipment library
    And I create a new Equipment object with player goid "player1"
    And I create a wearable item named "hat" at position "head" layer 0
    Then position_of should return nil for item "hat"

  Scenario: position_of searches left and right for generic position
    Given I require the Equipment library
    And I create a new Equipment object with player goid "player1"
    And I create a wearable item named "glove" at position "left_hand" layer 0
    And I wear the item "glove" on the equipment
    Then position_of with generic position "hand" should find item "glove"

  # ── each ────────────────────────────────────────────────────────
  Scenario: each iterates over equipped items
    Given I require the Equipment library
    And I create a new Equipment object with player goid "player1"
    And I create a wearable item named "hat" at position "head" layer 0
    And I wear the item "hat" on the equipment
    Then each should yield 1 item

  # ── [] accessor ─────────────────────────────────────────────────
  Scenario: bracket accessor returns equipment at position
    Given I require the Equipment library
    And I create a new Equipment object with player goid "player1"
    And I create a wearable item named "hat" at position "head" layer 0
    And I wear the item "hat" on the equipment
    Then bracket accessor for "head" should return the goid of item "hat"

  # ── show ────────────────────────────────────────────────────────
  Scenario: show displays equipment for self with items
    Given I require the Equipment library
    And I create a new Equipment object with player goid "player1"
    And I create a wearable item named "hat" at position "head" layer 0
    And I wear the item "hat" on the equipment
    Then show for "You" should include "You are wearing:"
    And show for "You" should include "hat"

  Scenario: show displays nothing when empty for self
    Given I require the Equipment library
    And I create a new Equipment object with player goid "player1"
    Then show for "You" should include "You are wearing nothing at all."

  Scenario: show displays equipment for another player with items
    Given I require the Equipment library
    And I create a new Equipment object with player goid "player1"
    And I create a wearable item named "hat" at position "head" layer 0
    And I wear the item "hat" on the equipment
    Then show for another wearer should include "is wearing:"
    And show for another wearer should include "hat"

  Scenario: show displays nothing when empty for another player
    Given I require the Equipment library
    And I create a new Equipment object with player goid "player1"
    Then show for another wearer should include "is wearing nothing at all."

  # ── show_position ───────────────────────────────────────────────
  Scenario: show_position returns nil for empty slot for self
    Given I require the Equipment library
    And I create a new Equipment object with player goid "player1"
    Then show_position for "head" for "You" should return nil

  Scenario: show_position returns description for occupied slot for self
    Given I require the Equipment library
    And I create a new Equipment object with player goid "player1"
    And I create a wearable item named "hat" at position "head" layer 0
    And I wear the item "hat" on the equipment
    Then show_position for "head" for "You" should include "hat on your head"

  Scenario: show_position for another wearer with single item at layer 0
    Given I require the Equipment library
    And I create a new Equipment object with player goid "player1"
    And I create a wearable item named "hat" at position "head" layer 0
    And I wear the item "hat" on the equipment
    Then show_position for "head" for another wearer should include "hat"

  Scenario: show_position for another wearer with layered items
    Given I require the Equipment library
    And I create a new Equipment object with player goid "player1"
    And I create a wearable item named "undershirt" at position "torso" layer 2
    And I create a wearable item named "necklace" at position "torso" layer 0
    And I wear the item "undershirt" on the equipment
    And I wear the item "necklace" on the equipment
    Then show_position for "torso" for another wearer should include "over"

  Scenario: show_position for another wearer with only inner layer
    Given I require the Equipment library
    And I create a new Equipment object with player goid "player1"
    And I create a wearable item named "undershirt" at position "torso" layer 2
    And I wear the item "undershirt" on the equipment
    Then show_position for "torso" for another wearer should include "undershirt"

  Scenario: show_position returns nil for empty slot for another wearer
    Given I require the Equipment library
    And I create a new Equipment object with player goid "player1"
    Then show_position for "head" for another wearer should return nil

  Scenario: show_position returns nil for another wearer with nil equipment
    Given I require the Equipment library
    And I create a new Equipment object with player goid "player1"
    Then show_position for "left_shoulder" for another wearer should return nil

  # ── show_wielding ───────────────────────────────────────────────
  Scenario: show_wielding shows wielded item for self
    Given I require the Equipment library
    And I create a new Equipment object with player goid "player1"
    And I create a weapon item named "sword" at position "left_wield" layer 0
    And I wear the item "sword" on the equipment
    Then show_wielding for "You" should include "You are wielding"
    And show_wielding for "You" should include "sword"

  Scenario: show_wielding shows nothing wielded for self
    Given I require the Equipment library
    And I create a new Equipment object with player goid "player1"
    Then show_wielding for "You" should include "You are not wielding anything."

  Scenario: show_wielding shows wielded item for another wearer
    Given I require the Equipment library
    And I create a new Equipment object with player goid "player1"
    And I create a weapon item named "sword" at position "right_wield" layer 0
    And I wear the item "sword" on the equipment
    Then show_wielding for another wearer should include "is wielding"

  Scenario: show_wielding shows nothing wielded for another wearer
    Given I require the Equipment library
    And I create a new Equipment object with player goid "player1"
    Then show_wielding for another wearer should include "is not wielding anything."

  # ── check_position ──────────────────────────────────────────────
  Scenario: check_position returns error for non-wearable item
    Given I require the Equipment library
    And I create a new Equipment object with player goid "player1"
    And I create a non-wearable item named "rock"
    Then check_position for item "rock" should return "You cannot wear rock."

  Scenario: check_position returns nil for free position
    Given I require the Equipment library
    And I create a new Equipment object with player goid "player1"
    And I create a wearable item named "hat" at position "head" layer 0
    Then check_position for item "hat" should return nil

  Scenario: check_position returns nil for free position with nil equipment slot
    Given I require the Equipment library
    And I create a new Equipment object with player goid "player1"
    And I create a wearable item named "hat" at position "head" layer 0
    Then check_position for item "hat" with position "head" should return nil

  Scenario: check_position returns error for mismatched position
    Given I require the Equipment library
    And I create a new Equipment object with player goid "player1"
    And I create a wearable item named "hat" at position "head" layer 0
    Then check_position for item "hat" with position "torso" should include "cannot wear"

  Scenario: check_position returns wearing conflict message
    Given I require the Equipment library
    And I create a new Equipment object with player goid "player1"
    And I create a wearable item named "hat1" at position "head" layer 0
    And I create a wearable item named "hat2" at position "head" layer 0
    And I wear the item "hat1" on the equipment
    Then check_position for item "hat2" should include "You are wearing"

  Scenario: check_position returns wield conflict message
    Given I require the Equipment library
    And I create a new Equipment object with player goid "player1"
    And I create a weapon item named "sword1" at position "left_wield" layer 0
    And I create a weapon item named "sword2" at position "left_wield" layer 0
    And I wear the item "sword1" on the equipment
    Then check_position for item "sword2" should include "You are wielding"

  Scenario: check_position with nil explicit position uses item default
    Given I require the Equipment library
    And I create a new Equipment object with player goid "player1"
    And I create a wearable item named "hat" at position "head" layer 0
    Then check_position for item "hat" with nil position should return nil

  Scenario: check_position with generic symmetric position (arm)
    Given I require the Equipment library
    And I create a new Equipment object with player goid "player1"
    And I create a wearable item named "bracer" at position "arm" layer 0
    Then check_position for item "bracer" should include "cannot wear"

  Scenario: check_position with wield position mismatch shows a hand
    Given I require the Equipment library
    And I create a new Equipment object with player goid "player1"
    And I create a wearable item named "hat" at position "head" layer 0
    Then check_position for item "hat" with position "wield" should include "a hand"

  Scenario: check_position with occupied layer at nil slot then non-nil
    Given I require the Equipment library
    And I create a new Equipment object with player goid "player1"
    And I create a wearable item named "hat1" at position "head" layer 0
    And I wear the item "hat1" on the equipment
    And I create a wearable item named "hat2" at position "head" layer 2
    Then check_position for item "hat2" should return nil

  # ── find_empty_position (private, exercised through wear) ───────
  Scenario: find_empty_position resolves symmetric positions
    Given I require the Equipment library
    And I create a new Equipment object with player goid "player1"
    And I create a wearable item named "ring" at position "ring_finger" layer 0
    And I wear the item "ring" on the equipment
    Then the item "ring" should be in the equipment at some position

  Scenario: find_empty_position returns nil when both sides full
    Given I require the Equipment library
    And I create a new Equipment object with player goid "player1"
    And I create a wearable item named "ring1" at position "ring_finger" layer 0
    And I create a wearable item named "ring2" at position "ring_finger" layer 0
    And I create a wearable item named "ring3" at position "ring_finger" layer 0
    And I wear the item "ring1" on the equipment
    And I wear the item "ring2" on the equipment
    When I try to wear item "ring3" on the equipment
    Then wear should return nil

  # ── nice (private, exercised through show) ──────────────────────
  Scenario: nice formats left_wield as left hand
    Given I require the Equipment library
    And I create a new Equipment object with player goid "player1"
    And I create a weapon item named "sword" at position "left_wield" layer 0
    And I wear the item "sword" on the equipment
    Then show_wielding for "You" should include "left hand"

  Scenario: nice formats right_wield as right hand
    Given I require the Equipment library
    And I create a new Equipment object with player goid "player1"
    And I create a weapon item named "sword" at position "right_wield" layer 0
    And I wear the item "sword" on the equipment
    Then show_wielding for "You" should include "right hand"

  Scenario: nice formats dual_wield as both hands
    Given I require the Equipment library
    And I create a new Equipment object with player goid "player1"
    And I create a weapon item named "greatsword" at position "dual_wield" layer 0
    And I wear the item "greatsword" on the equipment
    Then show_wielding for "You" should include "both hands"

  # ── sym (private, exercised through position_of) ────────────────
  Scenario: sym converts string position to symbol
    Given I require the Equipment library
    And I create a new Equipment object with player goid "player1"
    And I create a wearable item named "hat" at position "head" layer 0
    And I wear the item "hat" on the equipment
    Then position_of with string position "head" should return "head" for item "hat"

  # ── show_position with empty compact array ──────────────────────
  Scenario: show_position for self when equipment array has only nils
    Given I require the Equipment library
    And I create a new Equipment object with player goid "player1"
    And I set equipment slot "head" to an array of nils
    Then show_position for "head" for "You" should return nil

  # ── show_position for another wearer with only layer 0 item ─────
  Scenario: show_position for another wearer with only outermost layer
    Given I require the Equipment library
    And I create a new Equipment object with player goid "player1"
    And I create a wearable item named "crown" at position "head" layer 0
    And I wear the item "crown" on the equipment
    Then show_position for "head" for another wearer should include "crown"

  # ── show_position for another wearer with nil-only inner layers ──
  Scenario: show_position for another wearer returns nil when only nils in array
    Given I require the Equipment library
    And I create a new Equipment object with player goid "player1"
    And I set equipment slot "head" to array with nil first and nil rest
    Then show_position for "head" for another wearer should return nil
