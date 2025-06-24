require 'sequent'
require 'immudb'
require 'oj'
require 'prometheus/client'
require 'logger'
require_relative 'configuration'

module Aethyr
  module EventSourcing
    # Custom EventStore implementation for Sequent that persists events in ImmuDB using the Key-Value API.
    # This implementation provides atomic transactions, exponential backoff retry logic, snapshot support,
    # and comprehensive metrics collection through Prometheus monitoring.
    #
    # Key Features:
    # - Atomic event storage using ImmuDB's set_all operation
    # - Exponential backoff retry mechanism with configurable parameters
    # - Snapshot creation and retrieval for aggregate optimization
    # - Prometheus metrics for monitoring event commits and latency
    # - Thread-safe operations with proper connection management
    # - Comprehensive error handling and logging
    #
    # @author Jeffrey Phillips Freeman
    # @since 1.0.0
    class ImmudbEventStore
      include Sequent::Core::EventStore
      include Sequent::Core::Helpers::StringSupport

      # Prometheus metrics for monitoring event store performance and reliability
      EVENTS_COMMITTED_TOTAL = Prometheus::Client::Counter.new(
        :events_committed_total,
        docstring: 'Total number of events successfully committed to ImmuDB',
        labels: [:aggregate_type]
      )

      EVENT_COMMIT_LATENCY_SECONDS = Prometheus::Client::Histogram.new(
        :event_commit_latency_seconds,
        docstring: 'Time taken to commit events to ImmuDB in seconds',
        labels: [:aggregate_type],
        buckets: [0.001, 0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5, 10]
      )

      SNAPSHOT_OPERATIONS_TOTAL = Prometheus::Client::Counter.new(
        :snapshot_operations_total,
        docstring: 'Total number of snapshot operations performed',
        labels: [:operation_type, :aggregate_type]
      )

      # Register metrics with the default Prometheus registry
      Prometheus::Client.registry.register(EVENTS_COMMITTED_TOTAL)
      Prometheus::Client.registry.register(EVENT_COMMIT_LATENCY_SECONDS)
      Prometheus::Client.registry.register(SNAPSHOT_OPERATIONS_TOTAL)

      attr_reader :client, :config, :logger

      # Initializes the ImmuDB event store with connection configuration and logging
      # @param config [Configuration] Configuration instance with ImmuDB connection parameters
      # @param logger [Logger] Logger instance for diagnostic output
      def initialize(config = Configuration.instance, logger = Logger.new(STDOUT))
        @config = config
        @logger = logger
        @client = nil
        @connection_mutex = Mutex.new
        
        establish_connection!
        
        @logger.info("ImmudbEventStore initialized successfully")
        @logger.debug(@config.to_s)
      end

      # Commits a collection of events atomically to ImmuDB using the set_all operation.
      # This method implements the core event storage functionality with comprehensive
      # error handling, retry logic, and performance monitoring.
      #
      # @param aggregate_id [String] The unique identifier of the aggregate
      # @param events [Array<Sequent::Core::Event>] Collection of events to commit
      # @param expected_version [Integer] Expected version for optimistic concurrency control
      # @raise [Sequent::Core::EventStore::OptimisticLockingError] When version conflicts occur
      # @raise [ImmudbConnectionError] When ImmuDB operations fail after retries
      def commit_events(aggregate_id, events, expected_version)
        return if events.empty?

        aggregate_type = events.first.class.name.split('::').last
        
        start_time = Time.now
        @logger.debug("Committing #{events.size} events for aggregate #{aggregate_id}")

        # Verify optimistic locking by checking current version in ImmuDB
        current_version = get_current_version(aggregate_id)
        if current_version != expected_version
          raise Sequent::Core::EventStore::OptimisticLockingError.new(
            aggregate_id, expected_version, current_version
          )
        end

        # Prepare key-value pairs for atomic batch insertion
        kv_hash = prepare_event_batch(aggregate_id, events, expected_version)
        
        # Execute atomic commit with retry logic
        tx_id = with_retry("commit_events for #{aggregate_id}") do
          ensure_connection!
          result = @client.set_all(kv_hash)
          result.tx_id
        end

        # Record successful commit metrics and logging
        duration = Time.now - start_time
        EVENTS_COMMITTED_TOTAL.increment(labels: { aggregate_type: aggregate_type }, by: events.size)
        EVENT_COMMIT_LATENCY_SECONDS.observe(labels: { aggregate_type: aggregate_type }, value: duration)

        @logger.info("Successfully committed #{events.size} events for aggregate #{aggregate_id}, tx_id: #{tx_id}")
        
        tx_id
      rescue => e
        @logger.error("Failed to commit events for aggregate #{aggregate_id}: #{e.message}")
        @logger.debug(e.backtrace.join("\n"))
        raise
      end

      # Retrieves all events for a specific aggregate from ImmuDB in chronological order.
      # This method implements efficient event scanning with proper deserialization and validation.
      #
      # @param aggregate_id [String] The unique identifier of the aggregate
      # @return [Array<Sequent::Core::Event>] Ordered collection of events
      def find_events(aggregate_id)
        @logger.debug("Finding events for aggregate #{aggregate_id}")
        
        events = with_retry("find_events for #{aggregate_id}") do
          ensure_connection!
          
          # Scan all keys matching the event pattern for this aggregate
          key_prefix = event_key_prefix(aggregate_id)
          scan_result = @client.scan(
            seek_key: key_prefix,
            prefix: key_prefix,
            desc: false,
            since_tx: 0,
            no_wait: false,
            limit: 10000  # Configurable limit for large aggregates
          )
          
          # Deserialize and sort events by sequence number
          events = []
          scan_result.entries.each do |entry|
            event_data = Oj.load(entry.value, mode: :strict)
            event = deserialize_event(event_data)
            events << event if event
          end
          
          events.sort_by(&:sequence_number)
        end

        @logger.debug("Found #{events.size} events for aggregate #{aggregate_id}")
        events
      rescue => e
        @logger.error("Failed to find events for aggregate #{aggregate_id}: #{e.message}")
        @logger.debug(e.backtrace.join("\n"))
        raise
      end

      # Creates a snapshot of an aggregate's current state for performance optimization.
      # Snapshots reduce replay time by providing a cached state at a specific sequence number.
      #
      # @param aggregate_id [String] The unique identifier of the aggregate
      # @param aggregate [Object] The aggregate instance to snapshot
      # @param sequence_number [Integer] The sequence number at which the snapshot is taken
      def create_snapshot(aggregate_id, aggregate, sequence_number)
        aggregate_type = aggregate.class.name.split('::').last
        @logger.debug("Creating snapshot for aggregate #{aggregate_id} at sequence #{sequence_number}")

        snapshot_data = {
          aggregate_id: aggregate_id,
          aggregate_type: aggregate_type,
          sequence_number: sequence_number,
          timestamp: Time.now.utc.iso8601,
          data: serialize_aggregate(aggregate)
        }

        snapshot_key = snapshot_key_for(aggregate_id, sequence_number)
        snapshot_json = Oj.dump(snapshot_data, mode: :strict)

        with_retry("create_snapshot for #{aggregate_id}") do
          ensure_connection!
          @client.set(snapshot_key, snapshot_json)
        end

        SNAPSHOT_OPERATIONS_TOTAL.increment(
          labels: { operation_type: 'create', aggregate_type: aggregate_type }
        )

        @logger.info("Created snapshot for aggregate #{aggregate_id} at sequence #{sequence_number}")
      rescue => e
        @logger.error("Failed to create snapshot for aggregate #{aggregate_id}: #{e.message}")
        @logger.debug(e.backtrace.join("\n"))
        raise
      end

      # Retrieves the most recent snapshot for an aggregate to optimize event replay.
      # This method finds the latest snapshot that doesn't exceed the specified sequence number.
      #
      # @param aggregate_id [String] The unique identifier of the aggregate
      # @param max_sequence_number [Integer] Maximum sequence number for snapshot eligibility
      # @return [Hash, nil] Snapshot data or nil if no suitable snapshot exists
      def find_snapshot(aggregate_id, max_sequence_number = nil)
        @logger.debug("Finding snapshot for aggregate #{aggregate_id}, max_sequence: #{max_sequence_number}")

        snapshot = with_retry("find_snapshot for #{aggregate_id}") do
          ensure_connection!
          
          # Scan for snapshot keys in reverse order to find the most recent
          key_prefix = snapshot_key_prefix(aggregate_id)
          scan_result = @client.scan(
            seek_key: key_prefix,
            prefix: key_prefix,
            desc: true,  # Descending order to get most recent first
            since_tx: 0,
            no_wait: false,
            limit: 100
          )

          # Find the most recent snapshot within the sequence limit
          suitable_snapshot = nil
          scan_result.entries.each do |entry|
            snapshot_data = Oj.load(entry.value, mode: :strict)
            
            if max_sequence_number.nil? || snapshot_data[:sequence_number] <= max_sequence_number
              suitable_snapshot = snapshot_data
              break
            end
          end

          suitable_snapshot
        end

        if snapshot
          aggregate_type = snapshot[:aggregate_type]
          SNAPSHOT_OPERATIONS_TOTAL.increment(
            labels: { operation_type: 'find', aggregate_type: aggregate_type }
          )
          @logger.debug("Found snapshot for aggregate #{aggregate_id} at sequence #{snapshot[:sequence_number]}")
        else
          @logger.debug("No suitable snapshot found for aggregate #{aggregate_id}")
        end

        snapshot
      rescue => e
        @logger.error("Failed to find snapshot for aggregate #{aggregate_id}: #{e.message}")
        @logger.debug(e.backtrace.join("\n"))
        raise
      end

      # Closes the ImmuDB connection and performs cleanup operations.
      # This method should be called during application shutdown to ensure proper resource cleanup.
      def close
        @connection_mutex.synchronize do
          if @client
            @client.close
            @client = nil
            @logger.info("ImmuDB connection closed")
          end
        end
      end

      private

      # Establishes a connection to ImmuDB using the configured parameters
      # @raise [ImmudbConnectionError] If connection cannot be established
      def establish_connection!
        @connection_mutex.synchronize do
          @client = Immudb::Client.new(@config.connection_params)
          @client.login(@config.immudb_user, @config.immudb_pass)
        end
      rescue => e
        @logger.error("Failed to establish ImmuDB connection: #{e.message}")
        raise ImmudbConnectionError, "Unable to connect to ImmuDB: #{e.message}"
      end

      # Ensures that a valid connection exists, reconnecting if necessary
      def ensure_connection!
        @connection_mutex.synchronize do
          unless @client&.connected?
            @logger.warn("ImmuDB connection lost, attempting to reconnect")
            establish_connection!
          end
        end
      end

      # Executes a block with exponential backoff retry logic
      # @param operation_name [String] Name of the operation for logging
      # @yield Block to execute with retry logic
      # @return [Object] Result of the yielded block
      def with_retry(operation_name)
        attempt = 0
        begin
          yield
        rescue => e
          attempt += 1
          if attempt <= @config.retry_attempts
            delay = [@config.retry_base_delay * (2 ** (attempt - 1)), @config.retry_max_delay].min
            @logger.warn("#{operation_name} failed (attempt #{attempt}/#{@config.retry_attempts}), retrying in #{delay}s: #{e.message}")
            sleep(delay)
            retry
          else
            @logger.error("#{operation_name} failed after #{@config.retry_attempts} attempts: #{e.message}")
            raise
          end
        end
      end

      # Retrieves the current version/sequence number for an aggregate
      # @param aggregate_id [String] The unique identifier of the aggregate
      # @return [Integer] Current version number
      def get_current_version(aggregate_id)
        events = find_events(aggregate_id)
        events.empty? ? 0 : events.last.sequence_number
      end

      # Prepares a batch of events for atomic insertion into ImmuDB
      # @param aggregate_id [String] The unique identifier of the aggregate
      # @param events [Array<Sequent::Core::Event>] Events to prepare
      # @param expected_version [Integer] Starting version for sequence numbering
      # @return [Hash] Key-value pairs for batch insertion
      def prepare_event_batch(aggregate_id, events, expected_version)
        kv_hash = {}
        
        events.each_with_index do |event, index|
          sequence_number = expected_version + index + 1
          event_key = event_key_for(aggregate_id, sequence_number)
          event_data = serialize_event(event, aggregate_id, sequence_number)
          kv_hash[event_key] = Oj.dump(event_data, mode: :strict)
        end

        kv_hash
      end

      # Serializes an event into the ImmuDB storage format
      # @param event [Sequent::Core::Event] Event to serialize
      # @param aggregate_id [String] The unique identifier of the aggregate
      # @param sequence_number [Integer] Sequence number for the event
      # @return [Hash] Serialized event data
      def serialize_event(event, aggregate_id, sequence_number)
        {
          aggregate_id: aggregate_id,
          sequence_number: sequence_number,
          event_type: event.class.name,
          event_version: event.respond_to?(:event_version) ? event.event_version : 1,
          timestamp: Time.now.utc.iso8601,
          data: event.respond_to?(:to_hash) ? event.to_hash : event.instance_variables.each_with_object({}) do |var, hash|
            hash[var.to_s.delete('@')] = event.instance_variable_get(var)
          end
        }
      end

      # Deserializes event data from ImmuDB storage format
      # @param event_data [Hash] Serialized event data
      # @return [Sequent::Core::Event] Deserialized event instance
      def deserialize_event(event_data)
        event_class = Object.const_get(event_data[:event_type])
        event = event_class.new(event_data[:data])
        event.instance_variable_set(:@sequence_number, event_data[:sequence_number])
        event.instance_variable_set(:@aggregate_id, event_data[:aggregate_id])
        event
      rescue NameError => e
        @logger.error("Unknown event type: #{event_data[:event_type]}")
        nil
      end

      # Serializes an aggregate for snapshot storage
      # @param aggregate [Object] Aggregate to serialize
      # @return [Hash] Serialized aggregate data
      def serialize_aggregate(aggregate)
        if aggregate.respond_to?(:to_hash)
          aggregate.to_hash
        else
          aggregate.instance_variables.each_with_object({}) do |var, hash|
            hash[var.to_s.delete('@')] = aggregate.instance_variable_get(var)
          end
        end
      end

      # Generates the event key for ImmuDB storage
      # @param aggregate_id [String] The unique identifier of the aggregate
      # @param sequence_number [Integer] Sequence number of the event
      # @return [String] Formatted event key
      def event_key_for(aggregate_id, sequence_number)
        "evt/#{aggregate_id}/#{sequence_number.to_s.rjust(12, '0')}"
      end

      # Generates the event key prefix for scanning operations
      # @param aggregate_id [String] The unique identifier of the aggregate
      # @return [String] Event key prefix
      def event_key_prefix(aggregate_id)
        "evt/#{aggregate_id}/"
      end

      # Generates the snapshot key for ImmuDB storage
      # @param aggregate_id [String] The unique identifier of the aggregate
      # @param sequence_number [Integer] Sequence number of the snapshot
      # @return [String] Formatted snapshot key
      def snapshot_key_for(aggregate_id, sequence_number)
        "snap/#{aggregate_id}/#{sequence_number}"
      end

      # Generates the snapshot key prefix for scanning operations
      # @param aggregate_id [String] The unique identifier of the aggregate
      # @return [String] Snapshot key prefix
      def snapshot_key_prefix(aggregate_id)
        "snap/#{aggregate_id}/"
      end

      # Custom exception for ImmuDB connection errors
      class ImmudbConnectionError < StandardError; end
    end
  end
end 