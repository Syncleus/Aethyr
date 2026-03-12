Feature: ImmuDB Event Store
  The ImmudbEventStore class provides an event store implementation backed by ImmuDB
  with atomic transactions, retry logic, snapshot support, and Prometheus metrics.

  Scenario: Successful initialization establishes a connection
    Given I have a valid ImmuDB event store configuration
    When I create a new ImmudbEventStore instance
    Then the event store should be initialized successfully
    And the event store should have a client
    And the event store should have a config
    And the event store should have a logger

  Scenario: Initialization failure raises ImmudbConnectionError
    Given I have a configuration that causes connection failure
    When I attempt to create a new ImmudbEventStore instance
    Then an ImmudbConnectionError should be raised

  Scenario: Committing an empty events list is a no-op
    Given I have an initialized ImmuDB event store
    When I commit an empty list of events for aggregate "agg-1" with expected version 0
    Then no events should be written to ImmuDB

  Scenario: Committing events successfully writes to ImmuDB
    Given I have an initialized ImmuDB event store
    And the aggregate "agg-1" has no existing events
    When I commit 2 events for aggregate "agg-1" with expected version 0
    Then the events should be written atomically via set_all
    And a transaction id should be returned
    And the events committed counter should be incremented
    And the commit latency histogram should be observed

  Scenario: Committing events with version conflict raises OptimisticLockingError
    Given I have an initialized ImmuDB event store
    And the aggregate "agg-2" has 3 existing events
    When I attempt to commit events for aggregate "agg-2" with wrong expected version 0
    Then an OptimisticLockingError should be raised

  Scenario: Committing events that fail logs error and re-raises
    Given I have an initialized ImmuDB event store
    And the aggregate "agg-fail" has no existing events
    And set_all will fail permanently
    When I attempt to commit events for aggregate "agg-fail" with expected version 0
    Then the commit error should be logged and re-raised

  Scenario: Finding events returns deserialized events sorted by sequence
    Given I have an initialized ImmuDB event store
    And ImmuDB contains events for aggregate "agg-3"
    When I find events for aggregate "agg-3"
    Then the events should be returned deserialized and sorted by sequence number

  Scenario: Finding events with no events returns empty
    Given I have an initialized ImmuDB event store
    And ImmuDB contains no events for aggregate "agg-empty"
    When I find events for aggregate "agg-empty"
    Then an empty events list should be returned

  Scenario: Finding events handles unknown event types gracefully
    Given I have an initialized ImmuDB event store
    And ImmuDB contains an event with unknown type for aggregate "agg-bad-type"
    When I find events for aggregate "agg-bad-type"
    Then the unknown event should be skipped

  Scenario: Finding events that fail logs error and re-raises
    Given I have an initialized ImmuDB event store
    And scan will fail permanently
    When I attempt to find events for aggregate "agg-scan-fail"
    Then the find error should be logged and re-raised

  Scenario: Creating a snapshot with to_hash aggregate
    Given I have an initialized ImmuDB event store
    And I have an aggregate with to_hash support for "agg-snap-1"
    When I create a snapshot for aggregate "agg-snap-1" at sequence 5
    Then the snapshot should be stored in ImmuDB with the correct key
    And the snapshot operations counter should be incremented for create

  Scenario: Creating a snapshot without to_hash aggregate
    Given I have an initialized ImmuDB event store
    And I have an aggregate without to_hash support for "agg-snap-2"
    When I create a snapshot for aggregate "agg-snap-2" at sequence 3
    Then the snapshot should be stored using instance variables

  Scenario: Creating a snapshot that fails logs error and re-raises
    Given I have an initialized ImmuDB event store
    And I have an aggregate with to_hash support for "agg-snap-fail"
    And set will fail permanently
    When I attempt to create a snapshot for aggregate "agg-snap-fail" at sequence 1
    Then the snapshot error should be logged and re-raised

  Scenario: Finding the most recent snapshot
    Given I have an initialized ImmuDB event store
    And ImmuDB contains snapshots for aggregate "agg-snap-3"
    When I find snapshot for aggregate "agg-snap-3"
    Then the most recent snapshot should be returned
    And the snapshot operations counter should be incremented for find

  Scenario: Finding a snapshot with max_sequence_number filter
    Given I have an initialized ImmuDB event store
    And ImmuDB contains snapshots for aggregate "agg-snap-4" with various sequences
    When I find snapshot for aggregate "agg-snap-4" with max sequence 5
    Then only the snapshot within the sequence limit should be returned

  Scenario: Finding a snapshot when none exist
    Given I have an initialized ImmuDB event store
    And ImmuDB contains no snapshots for aggregate "agg-snap-none"
    When I find snapshot for aggregate "agg-snap-none"
    Then no snapshot should be returned

  Scenario: Finding a snapshot that fails logs error and re-raises
    Given I have an initialized ImmuDB event store
    And scan will fail permanently
    When I attempt to find snapshot for aggregate "agg-snap-fail2"
    Then the find snapshot error should be logged and re-raised

  Scenario: Closing the event store closes the client
    Given I have an initialized ImmuDB event store
    When I close the event store
    Then the client should be closed
    And the client reference should be nil

  Scenario: Closing when already closed is safe
    Given I have an initialized ImmuDB event store with no client
    When I close the event store
    Then no error should occur

  Scenario: Retry logic succeeds after transient failures
    Given I have an initialized ImmuDB event store
    When I execute an operation that fails twice then succeeds
    Then the operation should eventually succeed after retries

  Scenario: Retry logic exhausts all attempts
    Given I have an initialized ImmuDB event store
    When I execute an operation that always fails
    Then the error should be raised after exhausting retries

  Scenario: Reconnection when client is disconnected
    Given I have an initialized ImmuDB event store
    And the client reports as not connected
    When ensure_connection is called
    Then a reconnection should be attempted

  Scenario: Event key generation produces correct format
    Given I have an initialized ImmuDB event store
    Then event_key_for "agg-1" sequence 5 should return "evt/agg-1/000000000005"
    And event_key_prefix for "agg-1" should return "evt/agg-1/"
    And snapshot_key_for "agg-1" sequence 10 should return "snap/agg-1/10"
    And snapshot_key_prefix for "agg-1" should return "snap/agg-1/"

  Scenario: Serializing an event with to_hash
    Given I have an initialized ImmuDB event store
    When I serialize an event that supports to_hash for aggregate "agg-ser"
    Then the serialized data should include the event hash data

  Scenario: Serializing an event without to_hash
    Given I have an initialized ImmuDB event store
    When I serialize an event that does not support to_hash for aggregate "agg-ser2"
    Then the serialized data should include instance variable data

  Scenario: Serializing an event with event_version
    Given I have an initialized ImmuDB event store
    When I serialize an event with event_version for aggregate "agg-ver"
    Then the serialized data should include the event version

  Scenario: Deserializing a valid event
    Given I have an initialized ImmuDB event store
    When I deserialize valid event data
    Then a proper event instance should be returned with correct attributes

  Scenario: Deserializing an event with unknown type returns nil
    Given I have an initialized ImmuDB event store
    When I deserialize event data with unknown type
    Then nil should be returned and error logged

  Scenario: Getting current version with no events returns 0
    Given I have an initialized ImmuDB event store
    And the aggregate "agg-ver-0" has no existing events
    When I get the current version for aggregate "agg-ver-0"
    Then the current version should be 0

  Scenario: Getting current version with existing events
    Given I have an initialized ImmuDB event store
    And the aggregate "agg-ver-3" has 3 existing events
    When I get the current version for aggregate "agg-ver-3"
    Then the current version should be 3

  Scenario: Preparing event batch creates correct key-value pairs
    Given I have an initialized ImmuDB event store
    When I prepare a batch of 2 events for aggregate "agg-batch" starting at version 0
    Then the batch should contain 2 key-value pairs with correct keys and serialized values

  Scenario: ImmudbConnectionError is a StandardError
    Given I have loaded the ImmuDB event store module
    Then ImmudbConnectionError should be a subclass of StandardError

  # =========================================================================
  # Core ImmudbEventStore (lib/aethyr/core/event_sourcing/immudb_event_store.rb)
  # =========================================================================

  Scenario: Core file-based initialization when ImmuDB is unavailable
    Given I initialize a core event store in file-based mode
    Then the core store should use file-based storage
    And the core store metrics should be initialized to zero
    And the core store should have event counters
    And the core store retry settings should use defaults

  Scenario: Core initialization with custom retry settings
    Given I initialize a core event store with custom retry settings
    Then the core store retry count should be 5
    And the core store retry delay should be 1.0

  Scenario: Core ImmuDB initialization with pre-loaded client
    Given I pre-load the ImmuDB module with a mock client
    When I initialize a core event store with the mock ImmuDB client
    Then the core store should attempt ImmuDB initialization
    And the core ensure_database_exists should handle the error gracefully

  Scenario: Core ensure_database_exists when not using ImmuDB
    Given I initialize a core event store in file-based mode
    When I call core ensure_database_exists
    Then nothing should happen since ImmuDB is not active

  Scenario: Core store_events with empty list is a no-op
    Given I initialize a core event store in file-based mode
    When I call core store_events with an empty list
    Then no file-based events should be written
    And the core events_stored metric should be 0

  Scenario: Core store_events writes events to file-based storage
    Given I initialize a core event store in file-based mode
    When I store 3 core events for aggregate "core-agg-1"
    Then event files should exist for aggregate "core-agg-1" with 3 events
    And the core events_stored metric should be 3
    And the sequence file should show 3 for aggregate "core-agg-1"

  Scenario: Core store_events with ImmuDB path
    Given I initialize a core event store in immudb mode with mock client
    When I store 2 core events for aggregate "immudb-agg-1" via ImmuDB
    Then the mock client set_all should have been called
    And the mock client should have updated the sequence counter

  Scenario: Core load_events from file-based storage
    Given I initialize a core event store in file-based mode
    And I have stored 2 core events for aggregate "core-agg-load"
    When I load core events for aggregate "core-agg-load"
    Then 2 core events should be returned sorted by sequence number

  Scenario: Core load_events for nonexistent aggregate returns empty
    Given I initialize a core event store in file-based mode
    When I load core events for aggregate "nonexistent-agg"
    Then 0 core events should be returned sorted by sequence number

  Scenario: Core load_events via ImmuDB path
    Given I initialize a core event store in immudb mode with mock client
    And the mock client has events for aggregate "immudb-agg-load"
    When I load core events for aggregate "immudb-agg-load"
    Then 2 core events should be returned sorted by sequence number
    And the core events_loaded metric should reflect loaded events

  Scenario: Core load_events_for_aggregates returns hash of events
    Given I initialize a core event store in file-based mode
    And I have stored 2 core events for aggregate "multi-agg-1"
    And I have stored 3 core events for aggregate "multi-agg-2"
    When I load core events for aggregates "multi-agg-1" and "multi-agg-2"
    Then the result should have events for both aggregates

  Scenario: Core find_event_stream returns aggregate id, events, and snapshot
    Given I initialize a core event store in file-based mode
    And I have stored 2 core events for aggregate "stream-agg-1"
    When I find the core event stream for aggregate "stream-agg-1"
    Then the stream should contain the aggregate id "stream-agg-1"
    And the stream should contain 2 events
    And the stream should have a snapshot_event key

  Scenario: Core store_snapshot in file-based mode
    Given I initialize a core event store in file-based mode
    When I store a core snapshot for aggregate "snap-agg-1" at sequence 5
    Then a snapshot file should exist for aggregate "snap-agg-1"
    And the core snapshots_stored metric should be 1

  Scenario: Core store_snapshot via ImmuDB
    Given I initialize a core event store in immudb mode with mock client
    When I store a core snapshot for aggregate "snap-immudb-1" at sequence 3
    Then the mock client set should have been called with the snapshot key

  Scenario: Core load_snapshot from file-based storage
    Given I initialize a core event store in file-based mode
    And I have stored a core snapshot for aggregate "snap-load-1" at sequence 5
    When I load the core snapshot for aggregate "snap-load-1"
    Then the core snapshot should be returned with sequence number 5
    And the core snapshots_loaded metric should be 1

  Scenario: Core load_snapshot returns nil when no snapshot exists
    Given I initialize a core event store in file-based mode
    When I load the core snapshot for aggregate "snap-nonexist"
    Then the core snapshot should be nil

  Scenario: Core load_snapshot via ImmuDB with key found
    Given I initialize a core event store in immudb mode with mock client
    And the mock client has a snapshot for aggregate "snap-immudb-load"
    When I load the core snapshot for aggregate "snap-immudb-load"
    Then the core snapshot should be returned with sequence number 5

  Scenario: Core load_snapshot via ImmuDB with key not found
    Given I initialize a core event store in immudb mode with mock client
    And the mock client raises key not found for snapshots
    When I load the core snapshot for aggregate "snap-immudb-missing"
    Then the core snapshot should be nil

  Scenario: Core load_snapshot via ImmuDB with other error re-raises
    Given I initialize a core event store in immudb mode with mock client
    And the mock client raises a non-key-not-found error for snapshots
    When I attempt to load the core snapshot for aggregate "snap-immudb-err"
    Then a core error should be raised

  Scenario: Core get_aggregate_sequence file-based with no prior sequence
    Given I initialize a core event store in file-based mode
    When I get the core aggregate sequence for "new-agg"
    Then the core sequence should be 0

  Scenario: Core get_aggregate_sequence file-based with existing sequence
    Given I initialize a core event store in file-based mode
    And I have stored 4 core events for aggregate "seq-agg-1"
    When I get the core aggregate sequence for "seq-agg-1"
    Then the core sequence should be 4

  Scenario: Core get_aggregate_sequence via ImmuDB with existing sequence
    Given I initialize a core event store in immudb mode with mock client
    And the mock client returns sequence 7 for aggregate "immudb-seq-agg"
    When I get the core aggregate sequence for "immudb-seq-agg"
    Then the core sequence should be 7

  Scenario: Core get_aggregate_sequence via ImmuDB with key not found
    Given I initialize a core event store in immudb mode with mock client
    And the mock client raises key not found for sequence lookups
    When I get the core aggregate sequence for "immudb-seq-missing"
    Then the core sequence should be 0

  Scenario: Core get_aggregate_sequence via ImmuDB with other error
    Given I initialize a core event store in immudb mode with mock client
    And the mock client raises other error for sequence lookups
    When I get the core aggregate sequence for "immudb-seq-err"
    Then the core sequence should be 0

  Scenario: Core serialize_event produces marshaled binary
    Given I initialize a core event store in file-based mode
    When I serialize a core event with sequence number 3
    Then the serialized output should be a valid Marshal binary
    And the deserialized hash should contain sequence_number and class keys

  Scenario: Core deserialize_event reconstructs an event object
    Given I initialize a core event store in file-based mode
    When I serialize and deserialize a core event
    Then the deserialized event should have the correct class and attributes

  Scenario: Core deep_serialize handles Hash objects
    Given I initialize a core event store in file-based mode
    When I deep_serialize a Hash with nested values
    Then the result should be a Hash with serialized values

  Scenario: Core deep_serialize handles Array objects
    Given I initialize a core event store in file-based mode
    When I deep_serialize an Array
    Then the result should be an Array with serialized elements

  Scenario: Core deep_serialize handles Set objects
    Given I initialize a core event store in file-based mode
    When I deep_serialize a Set
    Then the result should have a __set__ key

  Scenario: Core deep_serialize handles Symbol objects
    Given I initialize a core event store in file-based mode
    When I deep_serialize a Symbol
    Then the result should have a __symbol__ key

  Scenario: Core deep_serialize handles GameObject objects
    Given I initialize a core event store in file-based mode
    When I deep_serialize a mock GameObject
    Then the result should have a __gameobject__ key

  Scenario: Core deep_serialize handles Proc objects
    Given I initialize a core event store in file-based mode
    When I deep_serialize a Proc
    Then the result should have a __proc__ key with unpersistable value

  Scenario: Core deep_serialize handles plain objects
    Given I initialize a core event store in file-based mode
    When I deep_serialize a plain integer
    Then the result should be the same integer

  Scenario: Core deep_deserialize handles __set__ marker
    Given I initialize a core event store in file-based mode
    When I deep_deserialize a hash with __set__ key
    Then the result should be a Set

  Scenario: Core deep_deserialize handles __symbol__ marker
    Given I initialize a core event store in file-based mode
    When I deep_deserialize a hash with __symbol__ key
    Then the result should be a Symbol

  Scenario: Core deep_deserialize handles __gameobject__ marker
    Given I initialize a core event store in file-based mode
    When I deep_deserialize a hash with __gameobject__ key
    Then the result should return the goid string

  Scenario: Core deep_deserialize handles __proc__ marker
    Given I initialize a core event store in file-based mode
    When I deep_deserialize a hash with __proc__ key
    Then the result should be nil for proc

  Scenario: Core deep_deserialize handles regular Hash
    Given I initialize a core event store in file-based mode
    When I deep_deserialize a regular hash
    Then the result should be a hash with deserialized values

  Scenario: Core deep_deserialize handles Array
    Given I initialize a core event store in file-based mode
    When I deep_deserialize an array
    Then the result should be an array with deserialized elements

  Scenario: Core deep_deserialize handles plain values
    Given I initialize a core event store in file-based mode
    When I deep_deserialize a plain string
    Then the result should be the same string

  Scenario: Core reset! in file-based mode clears everything
    Given I initialize a core event store in file-based mode
    And I have stored 2 core events for aggregate "reset-agg-1"
    When I call core reset!
    Then the file-based storage should be empty
    And the core metrics should be reset to zero
    And the core event counters should be cleared

  Scenario: Core reset! in ImmuDB mode clears via scan and delete
    Given I initialize a core event store in immudb mode with mock client
    When I call core reset! in ImmuDB mode
    Then the mock client should have scanned and deleted events
    And the core metrics should be reset to zero

  Scenario: Core statistics in file-based mode with stored events
    Given I initialize a core event store in file-based mode
    And I have stored 2 core events for aggregate "stats-agg-1"
    And I have stored a core snapshot for aggregate "stats-agg-1" at sequence 2
    When I get core statistics
    Then the statistics should include aggregate_count
    And the statistics should include event_count of 2
    And the statistics should include snapshot_count of 1

  Scenario: Core statistics in file-based mode with no directory
    Given I initialize a core event store in file-based mode
    And the file-based storage directory is removed
    When I get core statistics
    Then the statistics should not include aggregate_count

  Scenario: Core statistics in ImmuDB mode
    Given I initialize a core event store in immudb mode with mock client
    And the mock client returns scan results for statistics
    When I get core statistics
    Then the statistics should include aggregate_count
    And the statistics should include event_types

  Scenario: Core statistics in ImmuDB mode when scan fails
    Given I initialize a core event store in immudb mode with mock client
    And the mock client scan raises an error
    When I get core statistics
    Then the statistics should still return base metrics

  Scenario: Core with_retries succeeds on first attempt
    Given I initialize a core event store in file-based mode
    When I execute a core operation that succeeds immediately
    Then the core operation result should be "success"

  Scenario: Core with_retries retries and eventually succeeds
    Given I initialize a core event store with retry count 3 and minimal delay
    When I execute a core operation that fails twice then succeeds
    Then the core operation result should be "success"

  Scenario: Core with_retries exhausts all attempts and raises
    Given I initialize a core event store with retry count 2 and minimal delay
    When I execute a core operation that always fails
    Then the core operation error should be raised
    And the core store_failures metric should be incremented

  Scenario: Core store_events updates event_counters map
    Given I initialize a core event store in file-based mode
    When I store 2 core events for aggregate "counter-agg"
    And I store 3 core events for aggregate "counter-agg"
    Then the core event counter for "counter-agg" should be 5

  Scenario: Core get_aggregate_sequence reads from existing sequence file
    Given I initialize a core event store in file-based mode
    And a sequence file exists for aggregate "preseq-agg" with value 10
    When I get the core aggregate sequence for "preseq-agg"
    Then the core sequence should be 10

  Scenario: Core statistics in ImmuDB mode when scan fails on statistics
    Given I initialize a core event store in immudb mode with mock client
    And the mock client scan raises error specifically for statistics
    When I get core statistics
    Then the statistics should still return base metrics
