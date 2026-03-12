Feature: EventHandler component
  In order to dispatch game events reliably
  As a maintainer of the Aethyr engine
  I want EventHandler to correctly process, dispatch, and handle events.

  Background:
    Given a stubbed EventHandler environment

  # --- initialize (lines 11-13) already covered; sanity check ----------------
  Scenario: EventHandler initializes with an empty queue
    Then the evh event queue should be empty

  # --- stop (line 30) --------------------------------------------------------
  Scenario: stop sets running to false
    When I call evh stop
    Then the evh handler should not be running

  # --- start (line 35) -------------------------------------------------------
  Scenario: start sets running to true after stop
    When I call evh stop
    And I call evh start
    Then the evh handler should be running

  # --- run with empty queue (lines 18, 19 false, 25) -------------------------
  Scenario: run with an empty queue does nothing
    When I call evh run
    Then the evh handled events count should be 0

  # --- run with one event (lines 18, 19, 23, 25) ----------------------------
  Scenario: run with one event in the queue processes it
    Given an evh event is enqueued
    When I call evh run
    Then the evh handled events count should be 1

  # --- run with multiple events (lines 18-21, 23, 25) -----------------------
  Scenario: run with multiple events in the queue logs queue length
    Given 3 evh events are enqueued
    When I call evh run
    Then the evh handled events count should be 3
    And the evh log should contain "commands in queue"

  # --- run when mutex is already locked (line 18 return) ---------------------
  Scenario: run returns immediately when mutex is locked
    Given the evh mutex is already locked
    And an evh event is enqueued
    When I call evh run
    Then the evh handled events count should be 0

  # --- handle_event when not running (line 40) --------------------------------
  Scenario: handle_event returns immediately when not running
    When I call evh stop
    And I call evh handle_event with a valid event
    Then the evh dispatch count should be 0

  # --- handle_event with a non-Event argument (lines 41-43) ------------------
  Scenario: handle_event rejects a non-Event argument
    When I call evh handle_event with a string argument
    Then the evh log should contain "Invalid Event"

  # --- handle_event with valid event dispatched (lines 46, 52-55, 69) --------
  Scenario: handle_event dispatches a valid event to the correct module
    When I call evh handle_event with a dispatchable event
    Then the evh test module should have received the action

  # --- handle_event with e.at == 'me' (lines 57-58) -------------------------
  Scenario: handle_event replaces at me with player goid
    When I call evh handle_event with at set to me
    Then the evh last event at should equal the player goid

  # --- handle_event with e.object == 'me' (lines 59-60) ---------------------
  Scenario: handle_event replaces object me with player goid
    When I call evh handle_event with object set to me
    Then the evh last event object should equal the player goid

  # --- handle_event with e.target == 'me' (lines 61-62) ---------------------
  Scenario: handle_event replaces target me with player goid
    When I call evh handle_event with target set to me
    Then the evh last event target should equal the player goid

  # --- handle_event with :Future type (lines 65-66) --------------------------
  Scenario: handle_event routes Future events to manager
    When I call evh handle_event with a Future event
    Then the evh manager should have received a future event

  # --- handle_event with NameError (lines 69, 71-72) -------------------------
  Scenario: handle_event logs NameError for unknown module
    When I call evh handle_event with an unknown module type
    Then the evh log should contain "Error when running event"

  # --- handle_event with generic Exception (lines 74-75) ---------------------
  Scenario: handle_event logs generic exceptions
    When I call evh handle_event with a raising module type
    Then the evh log should contain "boom from EvhTestRaising"

  # --- handle_event with malformed event (line 79) ---------------------------
  Scenario: handle_event logs malformed events missing player
    When I call evh handle_event with a malformed event
    Then the evh log should contain "Mal-formed event"

  # --- handle_event with attached events (lines 48-49, 87-91, 94) -----------
  Scenario: handle_event processes attached events
    When I call evh handle_event with attached events
    Then the evh test module should have received 2 actions

  # --- handle_event with nested attached events (recursive get_attached) -----
  Scenario: handle_event processes nested attached events recursively
    When I call evh handle_event with nested attached events
    Then the evh test module should have received 3 actions

  # --- handle_event with event with no attached_events (line 48 false) -------
  Scenario: handle_event processes event without attached events
    When I call evh handle_event with a dispatchable event
    Then the evh test module should have received the action
