Feature: Reacts trait
  The Reacts module is mixed into GameObjects to allow them to respond to
  in-game events via scripted reactions.  It also provides many private
  helper methods used by reaction scripts (act, say, emote, follow, etc.)
  and the TickActions class for periodic behaviour.

  Background:
    Given the Reacts test environment is set up

  # ── init_reactor ──────────────────────────────────────────────────
  Scenario: init_reactor sets up reactor, reaction_files, and tick_actions
    Given a Reacts test object is created
    Then the Reacts object should have a reactor
    And the Reacts object should have an empty reaction_files set
    And the Reacts object should have a tick_actions instance

  # ── self.extended ─────────────────────────────────────────────────
  Scenario: extending an object with Reacts triggers init_reactor
    Given a plain extendable object exists
    When the plain object is extended with Reacts
    Then the extended object should have a reactor

  # ── initialize via include ────────────────────────────────────────
  Scenario: including Reacts and instantiating calls init_reactor via initialize
    Given a Reacts test object is created via include
    Then the included Reacts object should have a reactor

  # ── uses_reaction? ───────────────────────────────────────────────
  Scenario: uses_reaction? returns true for a loaded file
    Given a Reacts test object is created
    And the reactions_files set contains "goblin"
    Then uses_reaction? for "goblin" should be true

  Scenario: uses_reaction? returns false for an unloaded file
    Given a Reacts test object is created
    And the reactions_files set contains "goblin"
    Then uses_reaction? for "orc" should be false

  # ── load_reactions ───────────────────────────────────────────────
  Scenario: load_reactions adds the file and calls reactor load
    Given a Reacts test object is created
    When load_reactions is called with "goblin"
    Then the reaction_files set should include "goblin"
    And the reactor should have loaded "goblin"

  # ── reload_reactions ──────────────────────────────────────────────
  Scenario: reload_reactions clears and reloads from known files
    Given a Reacts test object is created
    And load_reactions has been called with "goblin"
    When reload_reactions is called
    Then the reactor should have been cleared
    And the reactor should have loaded "goblin" again

  Scenario: reload_reactions with no reaction files
    Given a Reacts test object is created
    And the reaction_files set is empty
    When reload_reactions is called
    Then the reactor should have been cleared

  # ── unload_reactions ──────────────────────────────────────────────
  Scenario: unload_reactions clears reactor and reaction_files
    Given a Reacts test object is created
    And load_reactions has been called with "goblin"
    When unload_reactions is called
    Then the reactor should have been cleared
    And the reaction_files set should be empty

  # ── alert: nil reactions ─────────────────────────────────────────
  Scenario: alert with nil reactions logs no reaction
    Given a Reacts test object is created
    And the reactor returns nil for react_to
    When alert is called with a test event
    Then the log should contain "No Reaction"

  # ── alert: reaction that does not parse ──────────────────────────
  Scenario: alert with a reaction that does not parse logs failure
    Given a Reacts test object is created
    And the reactor returns reactions "wave"
    And CommandParser parse returns nil
    When alert is called with a test event
    Then the log should contain "Action did not parse"

  # ── alert: reaction that parses to an action (raises) ────────────
  Scenario: alert with a reaction that parses raises an error
    Given a Reacts test object is created
    And the reactor returns reactions "attack goblin"
    And CommandParser parse returns a non-nil action
    When alert is called expecting a raise
    Then the alert should have raised an error

  # ── show_reactions ───────────────────────────────────────────────
  Scenario: show_reactions returns reactor listing
    Given a Reacts test object is created
    And the reactor list_reactions returns "say: greet"
    Then show_reactions should return "say: greet"

  Scenario: show_reactions returns message when reactor is nil
    Given a Reacts test object is created
    And the reactor is set to nil
    Then show_reactions should return "Reactor is nil"

  # ── run: empty tick_actions ──────────────────────────────────────
  Scenario: run with empty tick_actions does nothing extra
    Given a Reacts test object is created
    When run is called
    Then no error should be raised

  # ── run: tick countdown at zero, one-shot ────────────────────────
  Scenario: run fires a one-shot tick action at countdown zero
    Given a Reacts test object is created
    And a one-shot tick action is registered with countdown 0
    When run is called
    Then the one-shot tick action should have fired

  # ── run: tick countdown at zero, repeating ───────────────────────
  Scenario: run fires a repeating tick action and attempts reset
    Given a Reacts test object is created
    And a repeating tick action is registered with countdown 0 and interval 5
    When run is called expecting possible error
    Then the repeating tick action should have fired

  # ── run: tick countdown greater than zero ────────────────────────
  Scenario: run decrements countdown when greater than zero
    Given a Reacts test object is created
    And a one-shot tick action is registered with countdown 3
    When run is called
    Then the tick action countdown should be 2
    And the one-shot tick action should not have fired

  # ── Private: object_is_me? ───────────────────────────────────────
  Scenario: object_is_me? returns true when target is self
    Given a Reacts test object is created
    Then object_is_me? should return true for an event targeting self

  Scenario: object_is_me? returns false when target is something else
    Given a Reacts test object is created
    Then object_is_me? should return false for an event targeting another

  # ── Private: act ─────────────────────────────────────────────────
  Scenario: act returns false when parse fails
    Given a Reacts test object is created
    And CommandParser parse returns nil
    Then act with "gibberish" should return false

  Scenario: act raises when parse succeeds
    Given a Reacts test object is created
    And CommandParser parse returns a non-nil action
    Then act with "say hello" should raise an error

  # ── Private: emote ───────────────────────────────────────────────
  Scenario: emote delegates to act
    Given a Reacts test object is created
    And CommandParser parse returns nil
    Then emote with "waves" should return false

  # ── Private: say ─────────────────────────────────────────────────
  Scenario: say delegates to act
    Given a Reacts test object is created
    And CommandParser parse returns nil
    Then say with "hello" should return false

  # ── Private: sayto ───────────────────────────────────────────────
  Scenario: sayto with a string target delegates to act
    Given a Reacts test object is created
    And CommandParser parse returns nil
    Then sayto with target "bob" and message "hi" should return false

  Scenario: sayto with a GameObject target uses its name
    Given a Reacts test object is created
    And CommandParser parse returns nil
    Then sayto with a GameObject target and message "hi" should return false

  # ── Private: go ──────────────────────────────────────────────────
  Scenario: go delegates to act
    Given a Reacts test object is created
    And CommandParser parse returns nil
    Then go with "north" should return false

  # ── Private: get_object ──────────────────────────────────────────
  Scenario: get_object delegates to manager
    Given a Reacts test object is created
    Then get_object should delegate to the manager

  # ── Private: find ────────────────────────────────────────────────
  Scenario: find delegates to manager
    Given a Reacts test object is created
    Then find should delegate to the manager

  Scenario: find with a container delegates to manager
    Given a Reacts test object is created
    Then find with container should delegate to the manager

  # ── Private: random_act ──────────────────────────────────────────
  Scenario: random_act picks from given actions
    Given a Reacts test object is created
    And CommandParser parse returns nil
    Then random_act should call act with one of the given actions

  # ── Private: with_prob ───────────────────────────────────────────
  Scenario: with_prob executes action when probability is met
    Given a Reacts test object is created
    And CommandParser parse returns nil
    Then with_prob at probability 1.0 should execute the action

  Scenario: with_prob executes block when probability is met
    Given a Reacts test object is created
    Then with_prob at probability 1.0 with a block should yield

  Scenario: with_prob does nothing when probability is not met
    Given a Reacts test object is created
    Then with_prob at probability 0.0 should return false

  # ── Private: random_move ─────────────────────────────────────────
  Scenario: random_move moves in a random valid direction
    Given a Reacts test object is created
    And the manager provides a room with exits in the same area
    And CommandParser parse returns nil
    When random_move is called
    Then go should have been invoked

  Scenario: random_move does nothing when probability fails
    Given a Reacts test object is created
    When random_move is called with probability 0.0
    Then go should not have been invoked

  # ── Private: make_object ─────────────────────────────────────────
  Scenario: make_object creates via manager and adds to inventory
    Given a Reacts test object is created with inventory
    Then make_object should create and add to inventory

  Scenario: make_object creates via manager without inventory
    Given a Reacts test object is created
    Then make_object should create without adding to inventory

  # ── Private: delete_object ───────────────────────────────────────
  Scenario: delete_object delegates to manager
    Given a Reacts test object is created
    Then delete_object should delegate to manager

  # ── Private: said? ───────────────────────────────────────────────
  Scenario: said? returns true when phrase is in event
    Given a Reacts test object is created
    Then said? should return true for matching phrase

  Scenario: said? returns false when phrase is not in event
    Given a Reacts test object is created
    Then said? should return false for non-matching phrase

  Scenario: said? returns false when event has no phrase
    Given a Reacts test object is created
    Then said? should return false when event phrase is nil

  # ── Private: after_ticks ─────────────────────────────────────────
  Scenario: after_ticks registers a one-shot tick action
    Given a Reacts test object is created
    When after_ticks is called with 5 ticks
    Then a tick action with countdown 5 and no repeat should be registered

  # ── Private: every_ticks ─────────────────────────────────────────
  Scenario: every_ticks registers a repeating tick action
    Given a Reacts test object is created
    When every_ticks is called with 10 ticks
    Then a tick action with countdown 10 and repeat 10 should be registered

  # ── Private: action_sequence ─────────────────────────────────────
  Scenario: action_sequence without delay chains events
    Given a Reacts test object is created
    And CommandParser parse returns sequenceable stubs
    When action_sequence is called without delay
    Then the events should be chained together

  Scenario: action_sequence with delay wraps in future events
    Given a Reacts test object is created
    And CommandParser parse returns sequenceable stubs
    When action_sequence is called with delay 3
    Then the events should be chained with future event wrappers

  Scenario: action_sequence with initial_delay wraps first step
    Given a Reacts test object is created
    And CommandParser parse returns sequenceable stubs
    When action_sequence is called with initial_delay 2
    Then the first step should be a future event

  Scenario: action_sequence with loop connects last to first
    Given a Reacts test object is created
    And CommandParser parse returns sequenceable stubs
    When action_sequence is called with loop true
    Then the last step should be attached to the first

  # ── Private: teleport ────────────────────────────────────────────
  Scenario: teleport raises an error
    Given a Reacts test object is created
    Then teleport should raise an error about removed events

  # ── Private: follow ──────────────────────────────────────────────
  Scenario: follow a GameObject sets following and notifies
    Given a Reacts test object is created
    And a followable GameObject exists
    When follow is called with the followable object
    Then self should be following the object
    And the object should have self as a follower
    And the object should receive a default follow message

  Scenario: follow with a custom message uses that message
    Given a Reacts test object is created
    And a followable GameObject exists
    When follow is called with the followable object and message "I am here"
    Then the object should receive "I am here"

  Scenario: follow with an empty message outputs nothing
    Given a Reacts test object is created
    And a followable GameObject exists
    When follow is called with the followable object and message ""
    Then the object should not receive output

  Scenario: follow with a non-GameObject triggers lookup via manager
    Given a Reacts test object is created
    And the manager find returns nil
    When follow is called with a non-GameObject expecting error
    Then the follow error should reference undefined variable

  # ── Private: unfollow ────────────────────────────────────────────
  Scenario: unfollow when not following outputs error
    Given a Reacts test object is created
    When unfollow is called while not following
    Then self should output "Not following anyone"

  Scenario: unfollow a GameObject clears following and notifies
    Given a Reacts test object is created
    And a followable GameObject exists
    And self is following the followable object
    When unfollow is called with the followable object
    Then self should no longer be following
    And the object should not have self as a follower
    And the object should receive a default unfollow message

  Scenario: unfollow with a custom message uses that message
    Given a Reacts test object is created
    And a followable GameObject exists
    And self is following the followable object
    When unfollow is called with the followable object and message "Goodbye"
    Then the object should receive "Goodbye"

  Scenario: unfollow with nil lookup outputs error
    Given a Reacts test object is created
    And self has info.following set
    And the manager find returns nil
    When unfollow is called with a non-GameObject
    Then self should output "Cannot follow that."

  # ── TickActions class ────────────────────────────────────────────
  Scenario: TickActions initialize creates empty collection
    Given a new TickActions instance
    Then the TickActions length should be 0

  Scenario: TickActions append and length
    Given a new TickActions instance
    When an item is appended to TickActions
    Then the TickActions length should be 1

  Scenario: TickActions each_with_index iterates
    Given a new TickActions instance with items "a" and "b"
    Then TickActions each_with_index should yield both items

  Scenario: TickActions delete removes an item
    Given a new TickActions instance with items "a" and "b"
    When "a" is deleted from TickActions
    Then the TickActions length should be 1

  Scenario: TickActions marshal_dump returns empty string
    Given a new TickActions instance
    Then TickActions marshal_dump should return an empty string

  Scenario: TickActions marshal_load resets to empty
    Given a new TickActions instance with items "a" and "b"
    When TickActions marshal_load is called
    Then the TickActions length should be 0
