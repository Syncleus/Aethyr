Feature: Gary (Game ARraY) thread-safe container
  As a maintainer of the Aethyr engine
  I want the Gary container to store, retrieve, find, and delete game objects
  So that game objects can be shared safely across threads and managers.

  Background:
    Given a gary test environment is set up

  # --- initialize / empty? / length ------------------------------------------

  Scenario: A new Gary is empty
    When I create a new gary instance
    Then the gary should be empty
    And the gary length should be 0
    And the gary count should be 0

  # --- << (add) and length ----------------------------------------------------

  Scenario: Adding objects to the Gary
    When I create a new gary instance
    And I gary add an object with id "obj1" name "Sword" generic "weapon" alt_names "blade,steel"
    Then the gary length should be 1
    And the gary should not be empty

  # --- [] (lookup by id) ------------------------------------------------------

  Scenario: Looking up an object by game_object_id
    When I create a new gary instance
    And I gary add an object with id "obj1" name "Sword" generic "weapon" alt_names "blade"
    Then gary lookup by id "obj1" should return the object named "Sword"
    And gary lookup by id "nonexistent" should return nil

  # --- each (normal iteration) ------------------------------------------------

  Scenario: Iterating over all objects with each
    When I create a new gary instance
    And I gary add an object with id "obj1" name "Sword" generic "weapon" alt_names ""
    And I gary add an object with id "obj2" name "Shield" generic "armor" alt_names ""
    Then gary each should yield 2 objects

  # --- each (exception branch) ------------------------------------------------

  Scenario: Each catches exceptions and calls log
    When I create a new gary instance
    And I gary add an object with id "obj1" name "Sword" generic "weapon" alt_names ""
    And I iterate gary each with a block that raises an exception
    Then the gary log should have captured the exception message

  # --- type_count -------------------------------------------------------------

  Scenario: type_count returns counts per class
    When I create a new gary instance
    And I gary add a typed object with id "a1" of gary class "TypeA"
    And I gary add a typed object with id "a2" of gary class "TypeA"
    And I gary add a typed object with id "b1" of gary class "TypeB"
    Then gary type_count should show 2 for gary class "TypeA"
    And gary type_count should show 1 for gary class "TypeB"

  # --- delete with GameObject -------------------------------------------------

  Scenario: Deleting an object using a GameObject instance
    When I create a new gary instance
    And I gary add a game_object with id "go1" name "Potion"
    Then the gary length should be 1
    When I gary delete the game_object with id "go1"
    Then the gary length should be 0

  # --- delete with raw id ----------------------------------------------------

  Scenario: Deleting an object using a raw id string
    When I create a new gary instance
    And I gary add an object with id "raw1" name "Key" generic "key" alt_names ""
    Then the gary length should be 1
    When I gary delete by raw id "raw1"
    Then the gary length should be 0

  # --- remove alias -----------------------------------------------------------

  Scenario: remove is an alias for delete
    When I create a new gary instance
    And I gary add an object with id "rm1" name "Gem" generic "gem" alt_names ""
    When I gary remove by id "rm1"
    Then the gary length should be 0

  # --- find_by_id -------------------------------------------------------------

  Scenario: find_by_id returns object or nil
    When I create a new gary instance
    And I gary add an object with id "fb1" name "Ring" generic "ring" alt_names ""
    Then gary find_by_id "fb1" should return the object named "Ring"
    And gary find_by_id "missing" should return nil

  # --- find_by_generic: nil name ----------------------------------------------

  Scenario: find_by_generic with nil returns nil
    When I create a new gary instance
    Then gary find_by_generic with nil name should return nil

  # --- find_by_generic: non-string name ---------------------------------------

  Scenario: find_by_generic with non-string name converts to string
    When I create a new gary instance
    And I gary add an object with id "sym1" name "123" generic "numbered" alt_names ""
    Then gary find_by_generic with integer name 123 should return the object named "123"

  # --- find_by_generic: match on generic --------------------------------------

  Scenario: find_by_generic matches on generic name
    When I create a new gary instance
    And I gary add an object with id "g1" name "Magic Sword" generic "sword" alt_names ""
    Then gary find_by_generic "sword" should return the object named "Magic Sword"

  # --- find_by_generic: match on name -----------------------------------------

  Scenario: find_by_generic matches on object name
    When I create a new gary instance
    And I gary add an object with id "n1" name "Golden Ring" generic "jewelry" alt_names ""
    Then gary find_by_generic "golden ring" should return the object named "Golden Ring"

  # --- find_by_generic: match on alt_names ------------------------------------

  Scenario: find_by_generic matches on alternate names
    When I create a new gary instance
    And I gary add an object with id "alt1" name "Broad Sword" generic "weapon" alt_names "blade,steel"
    Then gary find_by_generic "blade" should return the object named "Broad Sword"

  # --- find_by_generic: case insensitive --------------------------------------

  Scenario: find_by_generic is case insensitive
    When I create a new gary instance
    And I gary add an object with id "ci1" name "Elven Bow" generic "bow" alt_names "longbow"
    Then gary find_by_generic "ELVEN BOW" should return the object named "Elven Bow"
    And gary find_by_generic "BOW" should return the object named "Elven Bow"
    And gary find_by_generic "LONGBOW" should return the object named "Elven Bow"

  # --- find_by_generic: with type filter (match) ------------------------------

  Scenario: find_by_generic with type filter matches correct type
    When I create a new gary instance
    And I gary add a typed_findable object with id "tf1" name "Iron Axe" generic "axe" alt_names "" of gary class "WeaponType"
    Then gary find_by_generic "axe" with type "WeaponType" should return the object named "Iron Axe"

  # --- find_by_generic: with type filter (no match) ---------------------------

  Scenario: find_by_generic with type filter returns nil for wrong type
    When I create a new gary instance
    And I gary add a typed_findable object with id "tf2" name "Iron Axe" generic "axe" alt_names "" of gary class "WeaponType"
    Then gary find_by_generic "axe" with type "ArmorType" should return nil

  # --- find_by_generic: no match returns nil ----------------------------------

  Scenario: find_by_generic with no match returns nil
    When I create a new gary instance
    And I gary add an object with id "nm1" name "Hat" generic "headwear" alt_names "cap"
    Then gary find_by_generic "nonexistent" should return nil

  # --- find -------------------------------------------------------------------

  Scenario: find uses find_by_id first then find_by_generic
    When I create a new gary instance
    And I gary add an object with id "f1" name "Wand" generic "stick" alt_names ""
    Then gary find "f1" should return the object named "Wand"
    And gary find "stick" should return the object named "Wand"
    And gary find "wand" should return the object named "Wand"
    And gary find "nothing" should return nil

  # --- find_all: class match with actual Class --------------------------------

  Scenario: find_all with class attribute and Class match
    When I create a new gary instance
    And I gary add a typed object with id "fa1" of gary class "TypeA"
    And I gary add a typed object with id "fa2" of gary class "TypeB"
    Then gary find_all by class "TypeA" should return 1 result
    And gary find_all by class "TypeB" should return 1 result

  # --- find_all: class match with string name ---------------------------------

  Scenario: find_all with class attribute and string class name
    When I create a new gary instance
    And I gary add a typed object with id "cs1" of gary class "GaryTestClassString"
    Then gary find_all by class string "GaryTestClassString" should return 1 result

  # --- find_all: class match with invalid const name --------------------------

  Scenario: find_all with class attribute and invalid class name
    When I create a new gary instance
    And I gary add a typed object with id "ic1" of gary class "TypeA"
    Then gary find_all by class string "CompletelyBogusClassName99" should return 0 results

  # --- find_all: "nil" coercion -----------------------------------------------

  Scenario: find_all coerces "nil" to nil and matches via else branch
    When I create a new gary instance
    And I gary add an object_with_ivar id "nil1" ivar "@gary_status" value nil
    And I gary add an object_with_ivar id "nil2" ivar "@gary_status" value "active"
    Then gary find_all with attrib "@gary_status" match "nil" should return 1 result

  # --- find_all: "true" coercion ----------------------------------------------

  Scenario: find_all coerces "true" to boolean true
    When I create a new gary instance
    And I gary add an object_with_ivar id "t1" ivar "@gary_flag" value true
    And I gary add an object_with_ivar id "t2" ivar "@gary_flag" value false
    Then gary find_all with attrib "@gary_flag" match "true" should return 1 result

  # --- find_all: "false" coercion ---------------------------------------------

  Scenario: find_all coerces "false" to boolean false
    When I create a new gary instance
    And I gary add an object_with_ivar id "f1" ivar "@gary_flag" value false
    And I gary add an object_with_ivar id "f2" ivar "@gary_flag" value true
    Then gary find_all with attrib "@gary_flag" match "false" should return 1 result

  # --- find_all: integer coercion ---------------------------------------------

  Scenario: find_all coerces digit string to integer
    When I create a new gary instance
    And I gary add an object_with_ivar id "i1" ivar "@gary_level" value_int 5
    And I gary add an object_with_ivar id "i2" ivar "@gary_level" value_int 10
    Then gary find_all with attrib "@gary_level" match "5" should return 1 result

  # --- find_all: symbol coercion ----------------------------------------------

  Scenario: find_all coerces colon-prefixed string to symbol
    When I create a new gary instance
    And I gary add an object_with_ivar id "s1" ivar "@gary_state" value_sym "idle"
    And I gary add an object_with_ivar id "s2" ivar "@gary_state" value_sym "active"
    Then gary find_all with attrib "@gary_state" match ":idle" should return 1 result

  # --- find_all: string match branch ------------------------------------------

  Scenario: find_all matches string attribute values case-insensitively
    When I create a new gary instance
    And I gary add an object_with_ivar id "str1" ivar "@gary_color" value "Red"
    And I gary add an object_with_ivar id "str2" ivar "@gary_color" value "Blue"
    Then gary find_all with attrib "@gary_color" match "red" should return 1 result

  # --- find_all: string match with non-string ivar (no match) -----------------

  Scenario: find_all string match skips non-string ivars
    When I create a new gary instance
    And I gary add an object_with_ivar id "ns1" ivar "@gary_color" value_int 42
    Then gary find_all with attrib "@gary_color" match "something" should return 0 results

  # --- event_store_stats: disabled --------------------------------------------

  Scenario: event_store_stats returns empty hash when disabled
    When I create a new gary instance
    Then gary event_store_stats should return an empty hash

  # --- event_store_stats: enabled ---------------------------------------------

  Scenario: event_store_stats delegates when event sourcing is enabled
    When I create a new gary instance
    And gary event sourcing is enabled
    Then gary event_store_stats should return the delegated stats

  # --- include? ---------------------------------------------------------------

  Scenario: include? returns true for present objects and false for absent
    When I create a new gary instance
    And I gary add an object with id "inc1" name "Helm" generic "helmet" alt_names ""
    Then gary include? "inc1" should be true
    And gary include? "helmet" should be true
    And gary include? "missing" should be false

  # --- has_any? ---------------------------------------------------------------

  Scenario: has_any? checks if any objects of a class exist
    When I create a new gary instance
    And I gary add a typed object with id "ha1" of gary class "TypeA"
    Then gary has_any? "TypeA" should be true
    And gary has_any? "TypeC" should be false

  # --- add alias --------------------------------------------------------------

  Scenario: add is an alias for <<
    When I create a new gary instance
    And I gary use add alias with id "add1" name "Staff" generic "staff" alt_names ""
    Then the gary length should be 1
    And gary lookup by id "add1" should return the object named "Staff"
