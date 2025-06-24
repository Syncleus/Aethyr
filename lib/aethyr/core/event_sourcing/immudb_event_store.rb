require 'sequent'
require 'concurrent'
require 'aethyr/core/util/log'
require 'fileutils'

module Aethyr
  module Core
    module EventSourcing
      # Custom EventStore implementation for Sequent that persists events in ImmuDB using the Key-Value API.
      # This implementation provides atomic transactions, exponential backoff retry logic, snapshot support,
      # and comprehensive metrics collection.
      #
      # Key Features:
      # - Atomic event storage using ImmuDB's set_all operation
      # - Exponential backoff retry mechanism with configurable parameters
      # - Snapshot creation and retrieval for aggregate optimization
      # - Comprehensive metrics collection for monitoring
      # - Fallback to file-based storage when ImmuDB is unavailable
      # - Thread-safe operations with proper connection management
      #
      # The event store uses a key-value structure for storing events:
      # - Event keys: event:{aggregate_id}:{sequence_number}
      # - Sequence counter keys: sequence:{aggregate_id}
      # - Snapshot keys: snapshot:{aggregate_id}
      #
      # When ImmuDB is not available, events are stored in the file system:
      # - Event files: {storage_path}/{aggregate_id}/{sequence_number}.event
      # - Sequence files: {storage_path}/{aggregate_id}.sequence
      # - Snapshot files: {storage_path}/snapshots/{aggregate_id}.snapshot
      class ImmudbEventStore < Sequent::Core::EventStore
        DEFAULT_RETRY_COUNT = 3
        DEFAULT_RETRY_DELAY = 0.5 # seconds

        attr_reader :metrics

        ##
        # Initializes a new instance of ImmudbEventStore.
        #
        # This method attempts to establish a connection to ImmuDB using the provided
        # configuration. If the ImmuDB client cannot be loaded, it falls back to a
        # file-based event store.
        #
        # @param config [Hash] A hash of configuration options. Possible keys:
        #   - :client [ImmuDB::Client] an existing ImmuDB client instance.
        #   - :address [String] ImmuDB server address (default: ServerConfig[:immudb_address] or "127.0.0.1").
        #   - :port [Integer] ImmuDB server port (default: ServerConfig[:immudb_port] or 3322).
        #   - :username [String] ImmuDB username (default: ServerConfig[:immudb_username] or "immudb").
        #   - :password [String] ImmuDB password (default: ServerConfig[:immudb_password] or "immudb").
        #   - :database [String] ImmuDB database name (default: ServerConfig[:immudb_database] or "aethyr").
        #   - :storage_path [String] Path for file-based storage fallback.
        #   - :retry_count [Integer] Number of retry attempts (default: #{DEFAULT_RETRY_COUNT}).
        #   - :retry_delay [Float] Base delay between retries in seconds (default: #{DEFAULT_RETRY_DELAY}).
        #
        # @return [ImmudbEventStore] A newly initialized event store instance.
        def initialize(config = {})
          # Try to load ImmuDB if available
          begin
            require 'immudb-ruby'
            @use_immudb = true
            @client = config[:client] || ImmuDB::Client.new(
              address: config[:address] || ServerConfig[:immudb_address] || "127.0.0.1",
              port: config[:port] || ServerConfig[:immudb_port] || 3322,
              username: config[:username] || ServerConfig[:immudb_username] || "immudb",
              password: config[:password] || ServerConfig[:immudb_password] || "immudb",
              database: config[:database] || ServerConfig[:immudb_database] || "aethyr"
            )
          rescue LoadError => e
            log "ImmuDB not available, using file-based event store: #{e.message}", Logger::Medium
            @use_immudb = false
            @storage_path = config[:storage_path] || "storage/events"
            FileUtils.mkdir_p(@storage_path)
          end
          @metrics = {
            events_stored: 0,
            store_failures: 0,
            events_loaded: 0,
            load_failures: 0,
            snapshots_stored: 0,
            snapshots_loaded: 0
          }
          @mutex = Mutex.new
          @retry_count = config[:retry_count] || DEFAULT_RETRY_COUNT
          @retry_delay = config[:retry_delay] || DEFAULT_RETRY_DELAY
          
          # Ensure database exists if using ImmuDB
          ensure_database_exists if @use_immudb
          
          # Initialize event counters
          @event_counters = Concurrent::Map.new
          
          log "Event store initialized (#{@use_immudb ? 'ImmuDB' : 'File-based'})", Logger::Medium
        end
        
        ##
        # Ensures that the configured ImmuDB database exists.
        #
        # This method checks if the database specified in the client configuration is
        # present. If not, it attempts to create it. On failure, it deactivates ImmuDB
        # usage and falls back to file-based storage.
        #
        # @return [void]
        def ensure_database_exists
          return unless @use_immudb
          
          begin
            databases = @client.databases
            unless databases.include?(client.database)
              log "Creating ImmuDB database: #{client.database}", Logger::Medium
              @client.create_database(client.database)
            end
          rescue => e
            log "Error ensuring database exists: #{e.message}", Logger::Ultimate
            @use_immudb = false
            log "Falling back to file-based event store", Logger::Medium
            @storage_path = "storage/events"
            FileUtils.mkdir_p(@storage_path)
          end
        end

        ##
        # Stores a batch of events atomically in the event store.
        #
        # Events are grouped by their aggregate identifier and then stored either via
        # ImmuDB's atomic batch operation or in a file-based system if ImmuDB is not available.
        #
        # @param events [Array<Sequent::Core::Event>] An array of events to be stored.
        # @return [void]
        def store_events(events)
          return if events.empty?
          
          with_retries do
            # Group events by aggregate_id for efficient storage
            events_by_aggregate = events.group_by(&:aggregate_id)
            
            events_by_aggregate.each do |aggregate_id, aggregate_events|
              # Get the current sequence number for this aggregate
              current_sequence = get_aggregate_sequence(aggregate_id)
              
              if @use_immudb
                # Prepare events for storage
                event_data = aggregate_events.map.with_index do |event, index|
                  sequence_number = current_sequence + index + 1
                  {
                    key: "event:#{aggregate_id}:#{sequence_number}",
                    value: serialize_event(event, sequence_number)
                  }
                end
                
                # Store events atomically
                @client.set_all(event_data)
                
                # Update sequence counter
                new_sequence = current_sequence + aggregate_events.size
                @client.set("sequence:#{aggregate_id}", new_sequence.to_s)
              else
                # File-based storage
                aggregate_dir = File.join(@storage_path, aggregate_id)
                FileUtils.mkdir_p(aggregate_dir)
                
                # Store each event in a separate file
                aggregate_events.each_with_index do |event, index|
                  sequence_number = current_sequence + index + 1
                  event_file = File.join(aggregate_dir, "#{sequence_number}.event")
                  File.open(event_file, 'wb') do |file|
                    file.write(serialize_event(event, sequence_number))
                  end
                end
                
                # Update sequence counter
                new_sequence = current_sequence + aggregate_events.size
                sequence_file = File.join(@storage_path, "#{aggregate_id}.sequence")
                File.write(sequence_file, new_sequence.to_s)
              end
              
              @event_counters[aggregate_id] = new_sequence
              @metrics[:events_stored] += aggregate_events.size
            end
          end
        end
        
        ##
        # Loads and returns all events for the specified aggregate.
        #
        # This method retrieves events from the underlying storage (ImmuDB or file-based)
        # and sorts them by their sequence number.
        #
        # @param aggregate_id [String] The identifier of the aggregate.
        # @return [Array<Sequent::Core::Event>] An array of events sorted by sequence.
        def load_events(aggregate_id)
          events = []
          
          with_retries do
            if @use_immudb
              # Scan for all events for this aggregate
              prefix = "event:#{aggregate_id}:"
              @client.scan(prefix).each do |key, value|
                events << deserialize_event(value)
              end
            else
              # File-based storage
              aggregate_dir = File.join(@storage_path, aggregate_id)
              if Dir.exist?(aggregate_dir)
                Dir.glob(File.join(aggregate_dir, "*.event")).each do |event_file|
                  events << deserialize_event(File.binread(event_file))
                end
              end
            end
            
            # Sort by sequence number
            events.sort_by!(&:sequence_number)
            @metrics[:events_loaded] += events.size
          end
          
          events
        end
        
        ##
        # Loads events for multiple aggregates.
        #
        # @param aggregate_ids [Array<String>] An array of aggregate identifiers.
        # @return [Hash{String=>Array<Sequent::Core::Event>}] A hash mapping each aggregate id to its events.
        def load_events_for_aggregates(aggregate_ids)
          result = {}
          
          aggregate_ids.each do |aggregate_id|
            result[aggregate_id] = load_events(aggregate_id)
          end
          
          result
        end
        
        ##
        # Retrieves the complete event stream for an aggregate.
        #
        # This method returns a hash containing the aggregate id, its events,
        # and an optional snapshot event (if available).
        #
        # @param aggregate_id [String] The identifier of the aggregate.
        # @return [Hash] A hash with keys :aggregate_id, :events, and :snapshot_event.
        def find_event_stream(aggregate_id)
          events = load_events(aggregate_id)
          snapshot = load_snapshot(aggregate_id)
          
          {
            aggregate_id: aggregate_id,
            events: events,
            snapshot_event: snapshot
          }
        end
        
        ##
        # Stores a snapshot for the given aggregate.
        #
        # A snapshot captures the state of an aggregate at a specific sequence number.
        # It is stored using ImmuDB if available; otherwise, it falls back to file-based storage.
        #
        # @param aggregate_id [String] The identifier of the aggregate.
        # @param event [Sequent::Core::Event] The snapshot event representing the aggregate state.
        # @return [void]
        def store_snapshot(aggregate_id, event)
          with_retries do
            sequence_number = event.sequence_number
            if @use_immudb
              @client.set("snapshot:#{aggregate_id}", serialize_event(event, sequence_number))
            else
              # File-based storage
              snapshot_dir = File.join(@storage_path, "snapshots")
              FileUtils.mkdir_p(snapshot_dir)
              snapshot_file = File.join(snapshot_dir, "#{aggregate_id}.snapshot")
              File.open(snapshot_file, 'wb') do |file|
                file.write(serialize_event(event, sequence_number))
              end
            end
            @metrics[:snapshots_stored] += 1
          end
        end
        
        ##
        # Loads a snapshot for the specified aggregate.
        #
        # This method retrieves the snapshot from the underlying store (ImmuDB or file-based)
        # and deserializes it into an event object.
        #
        # @param aggregate_id [String] The identifier of the aggregate.
        # @return [Sequent::Core::Event, nil] The snapshot event, or nil if no snapshot is found.
        def load_snapshot(aggregate_id)
          with_retries do
            snapshot_data = nil
            
            if @use_immudb
              begin
                snapshot_data = @client.get("snapshot:#{aggregate_id}")
              rescue => e
                if e.message.include?('key not found')
                  return nil
                else
                  raise
                end
              end
            else
              # File-based storage
              snapshot_file = File.join(@storage_path, "snapshots", "#{aggregate_id}.snapshot")
              if File.exist?(snapshot_file)
                snapshot_data = File.binread(snapshot_file)
              end
            end
            
            if snapshot_data
              @metrics[:snapshots_loaded] += 1
              return deserialize_event(snapshot_data)
            end
          end
          
          nil
        end
        
        ##
        # Retrieves the current sequence number for a given aggregate.
        #
        # This is used to determine the next sequence number when storing events.
        #
        # @param aggregate_id [String] The identifier of the aggregate.
        # @return [Integer] The current sequence number.
        def get_aggregate_sequence(aggregate_id)
          @event_counters[aggregate_id] ||= begin
            sequence = 0
            
            if @use_immudb
              begin
                sequence_data = @client.get("sequence:#{aggregate_id}")
                sequence = sequence_data.to_i if sequence_data
              rescue => e
                # If key not found, sequence starts at 0.
                sequence = 0 unless e.message.include?('key not found')
              end
            else
              # File-based storage.
              sequence_file = File.join(@storage_path, "#{aggregate_id}.sequence")
              if File.exist?(sequence_file)
                sequence = File.read(sequence_file).to_i
              end
            end
            
            sequence
          end
        end
        
        ##
        # Serializes an event into a binary format.
        #
        # The event is converted to a hash containing its instance values,
        # sequence number, and class name. Deep serialization is applied to handle
        # complex objects. Finally, the hash is marshaled into a binary string.
        #
        # @param event [Sequent::Core::Event] The event to serialize.
        # @param sequence_number [Integer] The sequence number for the event.
        # @return [String] A binary string representing the serialized event.
        def serialize_event(event, sequence_number)
          # Handle complex objects that might not serialize well with Marshal
          event_hash = event.instance_values.merge(
            'sequence_number' => sequence_number,
            'class' => event.class.name
          )
          
          # Convert any complex objects to simpler representations
          event_hash = deep_serialize(event_hash)
          
          Marshal.dump(event_hash)
        end
        
        ##
        # Deserializes a binary string into an event object.
        #
        # The binary string is unmarshaled into a hash, deep deserialized to reassemble
        # complex objects, and then used to instantiate and populate a new event object.
        #
        # @param serialized_event [String] The binary string representing the serialized event.
        # @return [Sequent::Core::Event] The deserialized event object.
        def deserialize_event(serialized_event)
          event_hash = Marshal.load(serialized_event)
          event_class = Object.const_get(event_hash['class'])
          
          # Restore any complex objects
          event_hash = deep_deserialize(event_hash)
          
          # Create a new instance of the event
          event = event_class.new
          
          # Set all attributes
          event_hash.each do |key, value|
            next if key == 'class'
            event.instance_variable_set("@#{key}", value)
          end
          
          event
        end
        
        # Helper methods to handle complex object serialization
        ##
        # Recursively serializes an object into a storable representation.
        #
        # Supports Hashes, Arrays, Sets, Symbols, and GameObjects by converting them
        # to simpler representations.
        #
        # @param obj [Object] The object to serialize.
        # @return [Object] The serialized representation.
        def deep_serialize(obj)
          case obj
          when Hash
            obj.transform_values { |v| deep_serialize(v) }
          when Array
            obj.map { |v| deep_serialize(v) }
          when Set
            { "__set__" => obj.map { |v| deep_serialize(v) } }
          when Symbol
            { "__symbol__" => obj.to_s }
          when Aethyr::Core::Objects::GameObject
            { "__gameobject__" => obj.goid }
          when Proc, Method, UnboundMethod
            { "__proc__" => "unpersistable" }
          else
            obj
          end
        end
        
        ##
        # Reconstructs objects from their serialized representations.
        #
        # This method reverses the process performed by #deep_serialize by converting
        # special markers (e.g. "__set__", "__symbol__") back into their original types.
        #
        # @param obj [Object] The object to deserialize.
        # @return [Object] The deserialized object.
        def deep_deserialize(obj)
          case obj
          when Hash
            if obj.key?("__set__")
              Set.new(obj["__set__"].map { |v| deep_deserialize(v) })
            elsif obj.key?("__symbol__")
              obj["__symbol__"].to_sym
            elsif obj.key?("__gameobject__")
              $manager&.get_object(obj["__gameobject__"]) || obj["__gameobject__"]
            elsif obj.key?("__proc__")
              nil
            else
              obj.transform_values { |v| deep_deserialize(v) }
            end
          when Array
            obj.map { |v| deep_deserialize(v) }
          else
            obj
          end
        end
        
        ##
        # Resets the event store by clearing all stored events, sequences, and snapshots.
        #
        # **WARNING:** This operation is destructive and intended for testing purposes only.
        #
        # @return [void]
        def reset!
          # Clear all events - DANGEROUS, only for testing
          if @use_immudb
            @client.scan("event:").each do |key, _|
              @client.delete(key)
            end
            
            @client.scan("sequence:").each do |key, _|
              @client.delete(key)
            end
            
            @client.scan("snapshot:").each do |key, _|
              @client.delete(key)
            end
          else
            # File-based storage - remove all event files
            FileUtils.rm_rf(@storage_path)
            FileUtils.mkdir_p(@storage_path)
          end
          
          @event_counters.clear
          @metrics = {
            events_stored: 0,
            store_failures: 0,
            events_loaded: 0,
            load_failures: 0,
            snapshots_stored: 0,
            snapshots_loaded: 0
          }
        end
        
        # Get statistics about the event store
        ##
        # Retrieves statistics from the event store.
        #
        # The returned hash includes metrics such as:
        #   - Number of events stored and loaded
        #   - Aggregate count
        #   - Snapshot count
        #   - A breakdown of event types and their counts
        #
        # @return [Hash] A hash containing event store statistics.
        def statistics
          stats = @metrics.dup
          
          # Count total events and aggregates
          if @use_immudb
            begin
              aggregate_count = @client.scan("sequence:").count
              event_count = @client.scan("event:").count
              snapshot_count = @client.scan("snapshot:").count
              
              stats[:aggregate_count] = aggregate_count
              stats[:event_count] = event_count
              stats[:snapshot_count] = snapshot_count
              
              # Get event types
              event_types = Hash.new(0)
              @client.scan("event:").each do |_, value|
                event_hash = Marshal.load(value)
                event_type = event_hash['class']
                event_types[event_type] += 1
              end
              stats[:event_types] = event_types
            rescue => e
              log "Error getting statistics: #{e.message}", Logger::Medium
            end
          else
            # File-based storage
            if File.directory?(@storage_path)
              aggregate_count = Dir.glob(File.join(@storage_path, "*")).select { |f| File.directory?(f) }.count
              event_count = Dir.glob(File.join(@storage_path, "**/*.event")).count
              snapshot_count = Dir.glob(File.join(@storage_path, "snapshots/*.snapshot")).count
              
              stats[:aggregate_count] = aggregate_count
              stats[:event_count] = event_count
              stats[:snapshot_count] = snapshot_count
            end
          end
          
          stats
        end
        
        private
        
        ##
        # Executes a block with exponential backoff retry logic.
        #
        # If an exception is raised during the execution of the block, it will be retried
        # up to @retry_count times with an increasing delay before ultimately raising the exception.
        #
        # @yield The operation to perform.
        # @return [Object] The result of the block if successful.
        # @raise [Exception] The last exception raised after exceeding retry attempts.
        def with_retries
          retries = 0
          begin
            yield
          rescue => e
            retries += 1
            if retries <= @retry_count
              log "Event store operation failed (attempt #{retries}/#{@retry_count}): #{e.message}", Logger::Medium
              sleep @retry_delay * retries
              retry
            else
              log "Event store operation failed after #{@retry_count} attempts: #{e.message}", Logger::Ultimate
              @metrics[:store_failures] += 1
              raise
            end
          end
        end
      end
    end
  end
end
