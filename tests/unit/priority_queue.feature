Feature: PriorityQueue (Fibonacci Heap)
  A pure-Ruby priority queue implemented as a Fibonacci Heap.
  It supports push, change_priority, delete, delete_min, and various query operations.

  Background:
    Given I require the priority queue library

  # --- Construction ----------------------------------------------------------

  Scenario: A new priority queue is empty
    Given a new priority queue
    Then the queue should be empty
    And the queue length should be 0
    And the queue min should be nil
    And the queue min_key should be nil
    And the queue min_priority should be nil

  # --- Push / [] = -----------------------------------------------------------

  Scenario: Pushing a single element
    Given a new priority queue
    When I push key "a" with priority 10
    Then the queue should not be empty
    And the queue length should be 1
    And the queue min should be key "a" with priority 10
    And the queue min_key should be "a"
    And the queue min_priority should be 10

  Scenario: Pushing multiple elements tracks minimum
    Given a new priority queue
    When I push key "x" with priority 50
    And I push key "y" with priority 20
    And I push key "z" with priority 30
    Then the queue min should be key "y" with priority 20
    And the queue length should be 3

  Scenario: Pushing a duplicate key calls change_priority
    Given a new priority queue
    When I push key "a" with priority 10
    And I push key "a" with priority 5
    Then the queue length should be 1
    And the queue min_priority should be 5

  # --- Bracket accessor [] ---------------------------------------------------

  Scenario: Bracket accessor returns priority for existing key
    Given a new priority queue
    When I push key "a" with priority 42
    Then priority of key "a" should be 42

  Scenario: Bracket accessor returns nil for missing key
    Given a new priority queue
    Then priority of key "missing" should be nil

  # --- has_key? ---------------------------------------------------------------

  Scenario: has_key? returns true for existing key
    Given a new priority queue
    When I push key "a" with priority 1
    Then the queue should have key "a"

  Scenario: has_key? returns false for missing key
    Given a new priority queue
    Then the queue should not have key "b"

  # --- each -------------------------------------------------------------------

  Scenario: each iterates over all elements
    Given a new priority queue
    When I push key "a" with priority 10
    And I push key "b" with priority 20
    And I push key "c" with priority 30
    Then iterating should yield 3 pairs

  # --- delete_min -------------------------------------------------------------

  Scenario: delete_min on empty queue returns nil
    Given a new priority queue
    Then delete_min should return nil

  Scenario: delete_min removes and returns the minimum element
    Given a new priority queue
    When I push key "a" with priority 10
    And I push key "b" with priority 5
    And I push key "c" with priority 20
    Then delete_min should return key "b" with priority 5
    And the queue length should be 2
    And the queue min should be key "a" with priority 10

  Scenario: delete_min on single element queue
    Given a new priority queue
    When I push key "only" with priority 1
    Then delete_min should return key "only" with priority 1
    And the queue should be empty
    And the queue length should be 0

  Scenario: delete_min returns elements in priority order
    Given a new priority queue
    When I push key "c" with priority 30
    And I push key "a" with priority 10
    And I push key "b" with priority 20
    And I push key "d" with priority 5
    And I push key "e" with priority 25
    Then successive delete_min calls should return keys in order "d,a,b,e,c"

  Scenario: delete_min with many elements triggers consolidation
    Given a new priority queue
    When I push 10 elements with keys "item0" through "item9" and sequential priorities
    Then successive delete_min calls should return 10 elements in ascending priority order

  # --- delete_min_return_key --------------------------------------------------

  Scenario: delete_min_return_key returns the key
    Given a new priority queue
    When I push key "a" with priority 1
    And I push key "b" with priority 0
    Then delete_min_return_key should return "b"
    And delete_min_return_key should return "a"
    And delete_min_return_key should return nil

  # --- delete_min_return_priority ---------------------------------------------

  Scenario: delete_min_return_priority returns the priority
    Given a new priority queue
    When I push key "a" with priority 1
    And I push key "b" with priority 0
    Then delete_min_return_priority should return 0
    And delete_min_return_priority should return 1
    And delete_min_return_priority should return nil

  # --- delete -----------------------------------------------------------------

  Scenario: delete returns nil for missing key
    Given a new priority queue
    When I push key "a" with priority 10
    Then deleting key "missing" should return nil

  Scenario: delete removes an element and returns key-priority pair
    Given a new priority queue
    When I push key "a" with priority 10
    And I push key "b" with priority 20
    And I push key "c" with priority 30
    Then deleting key "b" should return key "b" with priority 20
    And the queue length should be 2

  Scenario: delete the only element empties the queue
    Given a new priority queue
    When I push key "a" with priority 10
    Then deleting key "a" should return key "a" with priority 10
    And the queue should be empty

  Scenario: delete the min element
    Given a new priority queue
    When I push key "a" with priority 10
    And I push key "b" with priority 5
    And I push key "c" with priority 20
    Then deleting key "b" should return key "b" with priority 5
    And the queue min_key should be "a"

  Scenario: delete a non-root node after consolidation
    Given a new priority queue
    When I push key "a" with priority 1
    And I push key "b" with priority 2
    And I push key "c" with priority 3
    And I push key "d" with priority 4
    And I perform delete_min
    Then deleting key "d" should return key "d" with priority 4
    And the queue length should be 2

  Scenario: delete a node that is the rootlist anchor
    Given a new priority queue
    When I push key "a" with priority 10
    And I push key "b" with priority 5
    And I push key "c" with priority 20
    And I perform delete_min
    Then deleting key "a" should return key "a" with priority 10

  Scenario: delete node with children
    Given a new priority queue
    When I build a queue that produces child nodes via consolidation
    Then deleting a non-leaf node should succeed

  # --- change_priority --------------------------------------------------------

  Scenario: change_priority on non-existing key inserts it
    Given a new priority queue
    When I change priority of key "new" to 5
    Then the queue length should be 1
    And the queue min_key should be "new"

  Scenario: change_priority decreasing priority
    Given a new priority queue
    When I push key "a" with priority 10
    And I push key "b" with priority 20
    And I change priority of key "b" to 5
    Then the queue min_key should be "b"
    And the queue min_priority should be 5

  Scenario: change_priority increasing priority
    Given a new priority queue
    When I push key "a" with priority 10
    And I push key "b" with priority 20
    And I change priority of key "b" to 50
    Then the queue min_key should be "a"
    And priority of key "b" should be 50

  Scenario: change_priority with cascading cuts
    Given a new priority queue
    When I set up a heap that triggers cascading cuts
    Then the queue should be in a valid state

  Scenario: change_priority to same priority as parent
    Given a new priority queue
    When I push key "a" with priority 10
    And I push key "b" with priority 20
    And I push key "c" with priority 30
    And I perform delete_min
    And I change priority of key "c" to 20
    Then priority of key "c" should be 20

  # --- inspect ----------------------------------------------------------------

  Scenario: inspect returns a string representation
    Given a new priority queue
    When I push key "a" with priority 10
    Then inspecting the queue should include "PriorityQueue"

  # --- to_dot -----------------------------------------------------------------

  Scenario: to_dot on empty queue
    Given a new priority queue
    Then to_dot should return a valid dot graph

  Scenario: to_dot on non-empty queue
    Given a new priority queue
    When I push key "a" with priority 10
    And I push key "b" with priority 20
    Then to_dot should return a valid dot graph

  # --- display_dot ------------------------------------------------------------

  Scenario: display_dot does not raise
    Given a new priority queue
    When I push key "a" with priority 10
    Then calling display_dot should not raise

  # --- dup / initialize_copy --------------------------------------------------

  Scenario: dup creates an independent copy of an empty queue
    Given a new priority queue
    When I duplicate the queue
    Then the duplicate should be empty
    And the duplicate should be a different object

  Scenario: dup creates an independent deep copy
    Given a new priority queue
    When I push key "a" with priority 10
    And I push key "b" with priority 20
    And I push key "c" with priority 30
    And I duplicate the queue
    Then the duplicate min_key should be "a"
    And the duplicate length should be 3
    When I push key "d" with priority 1 on the original
    Then the duplicate length should be 3

  Scenario: dup of a queue after delete_min
    Given a new priority queue
    When I push key "a" with priority 10
    And I push key "b" with priority 5
    And I push key "c" with priority 20
    And I perform delete_min
    And I duplicate the queue
    Then the duplicate min_key should be "a"
    And the duplicate length should be 2

  # --- Node child= validation ------------------------------------------------

  Scenario: Node child= raises on circular child
    Given a new priority queue
    Then setting a node as its own child should raise "Circular Child"

  Scenario: Node child= raises on neighbour child
    Given a new priority queue
    Then setting a node neighbour as child should raise "Child is neighbour"

  # --- Node to_dot ------------------------------------------------------------

  Scenario: Node to_dot generates dot output
    Given a new priority queue
    When I push key "a" with priority 10
    And I push key "b" with priority 20
    And I push key "c" with priority 30
    And I perform delete_min
    Then calling node to_dot should produce output

  # --- Complex scenarios for deep coverage ------------------------------------

  Scenario: Multiple delete_min calls with consolidation produce correct ordering
    Given a new priority queue
    When I push 20 elements with descending priorities
    Then successive delete_min calls should return 20 elements in ascending priority order

  Scenario: Interleaved push and delete_min operations
    Given a new priority queue
    When I push key "a" with priority 50
    And I push key "b" with priority 30
    And I push key "c" with priority 40
    And I perform delete_min
    And I push key "d" with priority 10
    And I push key "e" with priority 60
    And I perform delete_min
    Then the queue min_key should be "c"
    And the queue length should be 3

  Scenario: Delete min when min equals rootlist
    Given a new priority queue
    When I push key "a" with priority 1
    And I push key "b" with priority 2
    And I push key "c" with priority 3
    Then delete_min should return key "a" with priority 1
    And the queue min_key should be "b"

  Scenario: Delete min when min has children
    Given a new priority queue
    When I push key "a" with priority 1
    And I push key "b" with priority 2
    And I push key "c" with priority 3
    And I push key "d" with priority 4
    And I perform delete_min
    And I push key "e" with priority 0
    Then delete_min should return key "e" with priority 0
    And the queue min_key should be "b"

  Scenario: Delete rootlist node
    Given a new priority queue
    When I push key "a" with priority 10
    And I push key "b" with priority 20
    And I push key "c" with priority 30
    And I push key "d" with priority 5
    And I perform delete_min
    Then deleting key "a" should return key "a" with priority 10

  Scenario: Deep heap operations for full cut_node coverage
    Given a new priority queue
    When I build a deep heap and perform cuts
    Then the queue should be in a valid state

  Scenario: change_priority decrease on child node triggers cut
    Given a new priority queue
    When I push key "a" with priority 1
    And I push key "b" with priority 2
    And I push key "c" with priority 3
    And I push key "d" with priority 4
    And I push key "e" with priority 5
    And I push key "f" with priority 6
    And I perform delete_min
    And I change priority of key "f" to 0
    Then the queue min_key should be "f"
    And the queue min_priority should be 0

  Scenario: Multiple change_priority operations trigger cascading cuts
    Given a new priority queue
    When I perform operations that trigger cascading cuts
    Then the queue should be in a valid state

  Scenario: delete_min leaves children in rootlist when rootlist is nil
    Given a new priority queue
    When I push key "a" with priority 1
    And I push key "b" with priority 2
    Then delete_min should return key "a" with priority 1
    And delete_min should return key "b" with priority 2
    And the queue should be empty

  Scenario: link_nodes with b2 priority less than b1 (swap case)
    Given a new priority queue
    When I push key "z" with priority 100
    And I push key "y" with priority 50
    And I push key "x" with priority 1
    And I push key "w" with priority 200
    And I perform delete_min
    Then the queue should be in a valid state

  Scenario: consolidate with different degree trees
    Given a new priority queue
    When I push 8 elements with keys "n0" through "n7" and sequential priorities
    And I perform delete_min
    And I perform delete_min
    And I perform delete_min
    Then the queue length should be 5
    And the queue should be in a valid state

  Scenario: delete node that is parent's only child
    Given a new priority queue
    When I push key "a" with priority 1
    And I push key "b" with priority 2
    And I push key "c" with priority 3
    And I push key "d" with priority 4
    And I perform delete_min
    Then deleting key "c" should succeed
    And deleting key "d" should succeed

  Scenario: change_priority decrease when already in rootlist does nothing extra
    Given a new priority queue
    When I push key "a" with priority 10
    And I push key "b" with priority 20
    And I change priority of key "b" to 5
    Then the queue min_key should be "b"

  Scenario: pop_min alias works like delete_min_return_key
    Given a new priority queue
    When I push key "a" with priority 1
    And I push key "b" with priority 0
    Then pop_min should return "b"

  Scenario: Enumerable methods work on the queue
    Given a new priority queue
    When I push key "a" with priority 10
    And I push key "b" with priority 20
    And I push key "c" with priority 30
    Then calling map on the queue should return 3 pairs
