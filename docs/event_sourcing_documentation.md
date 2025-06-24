# Comprehensive Documentation for Aethyr Event Sourcing System

I'll provide an in-depth documentation of the event sourcing system, covering all components, their interactions, and implementation details.

## 1. Event Sourcing System Overview

### 1.1 Introduction to Event Sourcing in Aethyr

The Aethyr event sourcing system provides a robust, persistent record of all state changes in the game world. Rather than storing just the current state of objects, the system records each change as an immutable event. This approach offers several advantages:

- **Complete History**: Every change to game objects is recorded, providing a full audit trail
- **Time Travel**: The ability to reconstruct the state of any object at any point in time
- **Resilience**: The system can recover from crashes by replaying events
- **Scalability**: Events can be processed asynchronously and in parallel
- **Extensibility**: New views of data can be created without changing the event model

The implementation uses the Sequent framework for event sourcing and CQRS (Command Query Responsibility Segregation), with ImmuDB as the primary event store and a file-based fallback mechanism.

### 1.2 System Architecture

The event sourcing system consists of several interconnected components:

1. **Commands**: Represent intentions to change the system state
2. **Command Handlers**: Process commands and apply events to aggregates
3. **Aggregates**: Encapsulate business logic and state changes
4. **Events**: Immutable records of state changes
5. **Event Store**: Persists events in ImmuDB or file system
6. **Projections**: Transform events into queryable data structures
7. **Integration Layer**: Connects event sourcing to existing game systems

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   Command   │────▶│   Command   │────▶│  Aggregate  │
│             │     │   Handler   │     │             │
└─────────────┘     └─────────────┘     └──────┬──────┘
                                               │
                                               ▼
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│  Projection │◀────│  Event      │◀────│   Event     │
│             │     │  Store      │     │             │
└─────────────┘     └─────────────┘     └─────────────┘
```

### 1.3 Key Components and Their Responsibilities

#### 1.3.1 Commands (lib/aethyr/core/event_sourcing/commands.rb)

Commands represent intentions to change the state of the system. They are validated before processing and contain all the data needed to perform an operation.

#### 1.3.2 Command Handlers (lib/aethyr/core/event_sourcing/command_handlers.rb)

Command handlers process commands and apply the appropriate events to aggregates. They enforce business rules and ensure consistency.

#### 1.3.3 Domain Models (lib/aethyr/core/event_sourcing/domain.rb)

Domain models define the aggregate roots that encapsulate business logic and state changes. They include:
- GameObject: Base aggregate for all game objects
- Player: Player-specific aggregate
- Room: Room-specific aggregate

#### 1.3.4 Events (lib/aethyr/core/event_sourcing/events.rb)

Events are immutable records of state changes. They are stored in the event store and used to reconstruct the state of aggregates.

#### 1.3.5 Event Store (lib/aethyr/core/event_sourcing/immudb_event_store.rb)

The event store persists events in ImmuDB or falls back to a file-based storage system. It provides atomic operations, retry logic, and snapshot support.

#### 1.3.6 Projections (lib/aethyr/core/event_sourcing/projections.rb)

Projections transform events into queryable data structures optimized for specific read operations.

#### 1.3.7 Setup and Configuration (lib/aethyr/core/event_sourcing/sequent_setup.rb)

The setup component initializes and configures the event sourcing system, including the event store, command handlers, and projections.

#### 1.3.8 Integration with Existing Systems

The event sourcing system integrates with the existing game systems through:
- Manager integration (lib/aethyr/core/components/manager.rb)
- Storage integration (lib/aethyr/core/components/storage.rb)
- GameObject integration (lib/aethyr/core/objects/game_object.rb)

## 2. Detailed Component Documentation

### 2.1 Commands (lib/aethyr/core/event_sourcing/commands.rb)

Commands represent intentions to change the state of the system. Each command class defines the attributes required for a specific operation and includes validation rules.

#### 2.1.1 GameObject Commands

```ruby
# Command to create a new game object
class CreateGameObject < Sequent::Command
  attrs id: String, name: String, generic: String, container_id: String
  validates :id, :name, presence: true
end

# Command to update a single attribute of a game object
class UpdateGameObjectAttribute < Sequent::Command
  attrs id: String, key: String, value: Object
  validates :id, :key, presence: true
end

# Command to update multiple attributes of a game object
class UpdateGameObjectAttributes < Sequent::Command
  attrs id: String, attributes: Hash
  validates :id, :attributes, presence: true
end

# Command to move a game object to a new container
class UpdateGameObjectContainer < Sequent::Command
  attrs id: String, container_id: String
  validates :id, :container_id, presence: true
end

# Command to delete a game object
class DeleteGameObject < Sequent::Command
  attrs id: String
  validates :id, presence: true
end
```

#### 2.1.2 Player Commands

```ruby
# Command to create a new player
class CreatePlayer < Sequent::Command
  attrs id: String, name: String, password_hash: String
  validates :id, :name, :password_hash, presence: true
end

# Command to update a player's password
class UpdatePlayerPassword < Sequent::Command
  attrs id: String, password_hash: String
  validates :id, :password_hash, presence: true
end

# Command to update a player's admin status
class UpdatePlayerAdminStatus < Sequent::Command
  attrs id: String, admin: Boolean
  validates :id, presence: true
end
```

#### 2.1.3 Room Commands

```ruby
# Command to create a new room
class CreateRoom < Sequent::Command
  attrs id: String, name: String, description: String
  validates :id, :name, presence: true
end

# Command to update a room's description
class UpdateRoomDescription < Sequent::Command
  attrs id: String, description: String
  validates :id, :description, presence: true
end

# Command to add an exit to a room
class AddRoomExit < Sequent::Command
  attrs id: String, direction: String, target_room_id: String
  validates :id, :direction, :target_room_id, presence: true
end

# Command to remove an exit from a room
class RemoveRoomExit < Sequent::Command
  attrs id: String, direction: String
  validates :id, :direction, presence: true
end
```

#### 2.1.4 Inventory and Equipment Commands

```ruby
# Command to add an item to an inventory
class AddItemToInventory < Sequent::Command
  attrs id: String, item_id: String, position: Object
  validates :id, :item_id, presence: true
end

# Command to remove an item from an inventory
class RemoveItemFromInventory < Sequent::Command
  attrs id: String, item_id: String
  validates :id, :item_id, presence: true
end

# Command to equip an item
class EquipItem < Sequent::Command
  attrs id: String, item_id: String, slot: String
  validates :id, :item_id, :slot, presence: true
end

# Command to unequip an item
class UnequipItem < Sequent::Command
  attrs id: String, item_id: String, slot: String
  validates :id, :item_id, :slot, presence: true
end
```

### 2.2 Command Handlers (lib/aethyr/core/event_sourcing/command_handlers.rb)

Command handlers process commands and apply the appropriate events to aggregates. They enforce business rules and ensure consistency.

```ruby
class GameObjectCommandHandler < Sequent::CommandHandler
  # GameObject commands
  on CreateGameObject do |command|
    repository.add_aggregate(Domain::GameObject.new(command.id, command.name, command.generic, command.container_id))
  end
  
  on UpdateGameObjectAttribute do |command|
    do_with_aggregate(command.id, Domain::GameObject) do |game_object|
      game_object.update_attribute(command.key, command.value)
    end
  end
  
  # ... additional handlers for other commands
end
```

The command handler uses the `on` method to register handlers for specific command types. Each handler retrieves the appropriate aggregate from the repository and calls methods on it to apply events.

### 2.3 Domain Models (lib/aethyr/core/event_sourcing/domain.rb)

Domain models define the aggregate roots that encapsulate business logic and state changes. They include methods to handle commands and apply events.

#### 2.3.1 GameObject Aggregate

```ruby
class GameObject < Sequent::AggregateRoot
  attr_reader :name, :generic, :container_id, :attributes
  
  def initialize(id, name, generic, container_id = nil)
    super(id)
    apply GameObjectCreated, name: name, generic: generic, container_id: container_id, attributes: {}
  end
  
  # Command handlers
  def update_attribute(key, value)
    apply GameObjectAttributeUpdated, key: key, value: value
  end
  
  # ... additional command handlers
  
  # Event handlers
  on GameObjectCreated do |event|
    @name = event.name
    @generic = event.generic
    @container_id = event.container_id
    @attributes = event.attributes || {}
    @deleted = false
  end
  
  # ... additional event handlers
end
```

#### 2.3.2 Player Aggregate

```ruby
class Player < GameObject
  attr_reader :password_hash, :admin
  
  def initialize(id, name, password_hash)
    super(id, name, "player")
    apply PlayerCreated, password_hash: password_hash, admin: false
  end
  
  # Command handlers
  def set_password(password_hash)
    apply PlayerPasswordUpdated, password_hash: password_hash
  end
  
  # ... additional command handlers
  
  # Event handlers
  on PlayerCreated do |event|
    @password_hash = event.password_hash
    @admin = event.admin
  end
  
  # ... additional event handlers
end
```

#### 2.3.3 Room Aggregate

```ruby
class Room < GameObject
  attr_reader :description, :exits
  
  def initialize(id, name, description)
    super(id, name, "room")
    apply RoomCreated, description: description, exits: {}
  end
  
  # Command handlers
  def update_description(description)
    apply RoomDescriptionUpdated, description: description
  end
  
  # ... additional command handlers
  
  # Event handlers
  on RoomCreated do |event|
    @description = event.description
    @exits = event.exits || {}
  end
  
  # ... additional event handlers
end
```

### 2.4 Events (lib/aethyr/core/event_sourcing/events.rb)

Events are immutable records of state changes. They are stored in the event store and used to reconstruct the state of aggregates.

#### 2.4.1 GameObject Events

```ruby
# Event indicating that a new game object has been created
class GameObjectCreated < Sequent::Event
  attrs name: String, generic: String, container_id: String, attributes: Hash
end

# Event indicating that an attribute of a game object has been updated
class GameObjectAttributeUpdated < Sequent::Event
  attrs key: String, value: Object
end

# Event indicating that multiple attributes of a game object have been updated
class GameObjectAttributesUpdated < Sequent::Event
  attrs attributes: Hash
end

# Event indicating that a game object has been moved to a new container
class GameObjectContainerUpdated < Sequent::Event
  attrs container_id: String
end

# Event indicating that a game object has been deleted
class GameObjectDeleted < Sequent::Event
end
```

#### 2.4.2 Player Events

```ruby
# Event indicating that a new player has been created
class PlayerCreated < Sequent::Event
  attrs password_hash: String, admin: Boolean
end

# Event indicating that a player's password has been updated
class PlayerPasswordUpdated < Sequent::Event
  attrs password_hash: String
end

# Event indicating that a player's admin status has been updated
class PlayerAdminStatusUpdated < Sequent::Event
  attrs admin: Boolean
end
```

#### 2.4.3 Room Events

```ruby
# Event indicating that a new room has been created
class RoomCreated < Sequent::Event
  attrs description: String, exits: Hash
end

# Event indicating that a room's description has been updated
class RoomDescriptionUpdated < Sequent::Event
  attrs description: String
end

# Event indicating that an exit has been added to a room
class RoomExitAdded < Sequent::Event
  attrs direction: String, target_room_id: String
end

# Event indicating that an exit has been removed from a room
class RoomExitRemoved < Sequent::Event
  attrs direction: String
end
```

#### 2.4.4 Inventory and Equipment Events

```ruby
# Event indicating that an item has been added to an inventory
class ItemAddedToInventory < Sequent::Event
  attrs item_id: String, position: Object
end

# Event indicating that an item has been removed from an inventory
class ItemRemovedFromInventory < Sequent::Event
  attrs item_id: String
end

# Event indicating that an item has been equipped
class ItemEquipped < Sequent::Event
  attrs item_id: String, slot: String
end

# Event indicating that an item has been unequipped
class ItemUnequipped < Sequent::Event
  attrs item_id: String, slot: String
end
```

### 2.5 Event Store (lib/aethyr/core/event_sourcing/immudb_event_store.rb)

The event store persists events in ImmuDB or falls back to a file-based storage system. It provides atomic operations, retry logic, and snapshot support.

#### 2.5.1 Initialization and Configuration

```ruby
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
  
  # Initialize metrics, mutex, and retry configuration
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
```

#### 2.5.2 Storing Events

```ruby
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
```

#### 2.5.3 Loading Events

```ruby
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
```

#### 2.5.4 Snapshot Management

```ruby
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
```

#### 2.5.5 Serialization and Deserialization

```ruby
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
```

#### 2.5.6 Retry Logic

```ruby
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
```

### 2.6 Projections (lib/aethyr/core/event_sourcing/projections.rb)

Projections transform events into queryable data structures optimized for specific read operations.

#### 2.6.1 GameObject Projector

```ruby
class GameObjectProjector < Sequent::Projector
  manages_tables :game_objects
  
  on GameObjectCreated do |event|
    create_record(
      :game_objects,
      aggregate_id: event.aggregate_id,
      name: event.name,
      generic: event.generic,
      container_id: event.container_id,
      attributes: Marshal.dump(event.attributes || {}),
      deleted: false
    )
  end
  
  on GameObjectAttributeUpdated do |event|
    update_all_records(
      :game_objects,
      {aggregate_id: event.aggregate_id},
      {attributes: -> (record) { Marshal.dump(Marshal.load(record.attributes).merge(event.key => event.value)) }}
    )
  end
  
  # ... additional event handlers
end
```

#### 2.6.2 Player Projector

```ruby
class PlayerProjector < Sequent::Projector
  manages_tables :players
  
  on PlayerCreated do |event|
    create_record(
      :players,
      aggregate_id: event.aggregate_id,
      password_hash: event.password_hash,
      admin: event.admin
    )
  end
  
  # ... additional event handlers
end
```

#### 2.6.3 Room Projector

```ruby
class RoomProjector < Sequent::Projector
  manages_tables :rooms
  
  on RoomCreated do |event|
    create_record(
      :rooms,
      aggregate_id: event.aggregate_id,
      description: event.description,
      exits: Marshal.dump(event.exits || {})
    )
  end
  
  # ... additional event handlers
end
```

### 2.7 Setup and Configuration (lib/aethyr/core/event_sourcing/sequent_setup.rb)

The setup component initializes and configures the event sourcing system, including the event store, command handlers, and projections.

```ruby
def self.configure
  log "Configuring Sequent with event store", Logger::Medium
  
  # Configure Sequent
  Sequent.configure do |config|
    config.event_store = ImmudbEventStore.new
    
    # Register command handlers
    config.command_handlers = [
      GameObjectCommandHandler.new
    ]
    
    # Register event handlers
    config.event_handlers = [
      GameObjectProjector.new,
      PlayerProjector.new,
      RoomProjector.new
    ]
    
    # Configure event publishing
    config.event_publisher = Sequent::Core::EventPublisher.new
  end
  
  log "Sequent configured successfully", Logger::Medium
  return true
end
```

### 2.8 Integration with Existing Systems

#### 2.8.1 Manager Integration (lib/aethyr/core/components/manager.rb)

The Manager class integrates with the event sourcing system by:
- Initializing the event sourcing system during startup
- Rebuilding world state from events
- Recording events for player creation and password updates
- Recording events for game object creation and deletion

```ruby
# Initialize event sourcing if enabled
if ServerConfig[:event_sourcing_enabled]
  log "Initializing event sourcing", Logger::Medium
  begin
    require 'aethyr/core/event_sourcing/sequent_setup'
    Aethyr::Core::EventSourcing::SequentSetup.configure
  rescue LoadError => e
    log "Event sourcing disabled: #{e.message}", Logger::Medium
    ServerConfig[:event_sourcing_enabled] = false
  end
end

# Rebuild world state from events if event sourcing is enabled
if ServerConfig[:event_sourcing_enabled]
  log "Rebuilding world state from events", Logger::Medium
  Aethyr::Core::EventSourcing::SequentSetup.rebuild_world_state
end
```

#### 2.8.2 Storage Integration (lib/aethyr/core/components/storage.rb)

The StorageMachine class integrates with the event sourcing system by:
- Ensuring players and objects exist in the event store
- Recording password updates in the event store
- Providing a migration utility to populate the event store from existing data

```ruby
# If event sourcing is enabled, ensure player exists in event store
if defined?(ServerConfig) && ServerConfig[:event_sourcing_enabled] && password
  # Check if player exists in event store
  begin
    Sequent.aggregate_repository.load_aggregate(player.goid)
  rescue Sequent::Core::AggregateRepository::AggregateNotFound
    # Create player in event store
    password_hash = Digest::MD5.new.update(password).to_s
    command = Aethyr::Core::EventSourcing::CreatePlayer.new(
      id: player.goid,
      name: player.name,
      password_hash: password_hash
    )
    Sequent.command_service.execute_commands(command)
  end
end
```

#### 2.8.3 GameObject Integration (lib/aethyr/core/objects/game_object.rb)

The GameObject class integrates with the event sourcing system by:
- Recording attribute updates in the event store
- Recording container changes in the event store

```ruby
# Sets the long description of the object with event sourcing support
def long_desc=(desc)
  @long_desc = desc
  
  # If event sourcing is enabled, emit attribute update event
  if defined?(ServerConfig) && ServerConfig[:event_sourcing_enabled] && $manager && defined?(Sequent)
    begin
      command = Aethyr::Core::EventSourcing::UpdateGameObjectAttribute.new(
        id: @game_object_id,
        key: 'long_desc',
        value: desc
      )
      Sequent.command_service.execute_commands(command)
    rescue => e
      log "Failed to record event: #{e.message}", Logger::Medium
    end
  end
end
```

## 3. Configuration and Utilities

### 3.1 Configuration (lib/aethyr/event_sourcing/configuration.rb)

The Configuration class manages event sourcing settings and ImmuDB connection parameters. It implements the Singleton pattern to ensure consistent configuration across the application.

```ruby
class Configuration
  include Singleton

  # Default configuration values
  DEFAULT_IMMUDB_HOST = 'localhost'
  DEFAULT_IMMUDB_PORT = 3322
  DEFAULT_IMMUDB_USER = 'immudb'
  DEFAULT_IMMUDB_PASS = 'immudb'
  DEFAULT_SNAPSHOT_FREQUENCY = 500
  DEFAULT_RETRY_ATTEMPTS = 5
  DEFAULT_RETRY_BASE_DELAY = 0.1
  DEFAULT_RETRY_MAX_DELAY = 5.0

  attr_reader :immudb_host, :immudb_port, :immudb_user, :immudb_pass,
              :snapshot_frequency, :retry_attempts, :retry_base_delay, :retry_max_delay

  def initialize
    # Load configuration from environment variables or use defaults
    @immudb_host = ENV['IMMUDB_HOST'] || DEFAULT_IMMUDB_HOST
    @immudb_port = (ENV['IMMUDB_PORT'] || DEFAULT_IMMUDB_PORT).to_i
    @immudb_user = ENV['IMMUDB_USER'] || DEFAULT_IMMUDB_USER
    @immudb_pass = ENV['IMMUDB_PASS'] || DEFAULT_IMMUDB_PASS
    @snapshot_frequency = (ENV['SNAPSHOT_FREQUENCY'] || DEFAULT_SNAPSHOT_FREQUENCY).to_i
    @retry_attempts = (ENV['RETRY_ATTEMPTS'] || DEFAULT_RETRY_ATTEMPTS).to_i
    @retry_base_delay = (ENV['RETRY_BASE_DELAY'] || DEFAULT_RETRY_BASE_DELAY).to_f
    @retry_max_delay = (ENV['RETRY_MAX_DELAY'] || DEFAULT_RETRY_MAX_DELAY).to_f

    validate_configuration!
  end

  # ... additional methods
end
```

### 3.2 Event Store Statistics (lib/aethyr/event_store_stats.rb)

The event_store_stats.rb script displays statistics about the event store, including the number of events, aggregates, and snapshots.

```ruby
if $manager && ServerConfig[:event_sourcing_enabled]
  puts "Event Store Statistics"
  puts "======================"
  
  stats = $manager.event_store_stats
  
  if stats.empty?
    puts "Event store not available or no statistics available"
  else
    puts "Total events stored: #{stats[:events_stored]}"
    puts "Total events loaded: #{stats[:events_loaded]}"
    puts "Total snapshots stored: #{stats[:snapshots_stored]}"
    puts "Total snapshots loaded: #{stats[:snapshots_loaded]}"
    puts "Store failures: #{stats[:store_failures]}"
    puts "Load failures: #{stats[:load_failures]}"
    
    # ... additional statistics
  end
else
  puts "Error: Manager not initialized or event sourcing not enabled"
end
```

### 3.3 Migration Utility (lib/aethyr/migrate_to_event_store.rb)

The migrate_to_event_store.rb script migrates existing game objects to the event store.

```ruby
if $manager && $manager.storage
  puts "Starting migration to event store..."
  result = $manager.storage.migrate_to_event_store
  if result
    puts "Migration completed successfully!"
  else
    puts "Migration failed. Check logs for details."
  end
else
  puts "Error: Manager or storage not initialized"
end
```

## 4. Implementation Details

### 4.1 Event Storage and Retrieval

Events are stored in ImmuDB using a key-value structure:
- Event keys: `event:{aggregate_id}:{sequence_number}`
- Sequence counter keys: `sequence:{aggregate_id}`
- Snapshot keys: `snapshot:{aggregate_id}`

When ImmuDB is not available, events are stored in the file system:
- Event files: `{storage_path}/{aggregate_id}/{sequence_number}.event`
- Sequence files: `{storage_path}/{aggregate_id}.sequence`
- Snapshot files: `{storage_path}/snapshots/{aggregate_id}.snapshot`

### 4.2 Serialization and Deserialization

Events are serialized using Ruby's Marshal library, with special handling for complex objects:
- Sets are converted to arrays with a special marker
- Symbols are converted to strings with a special marker
- GameObject references are converted to GOIDs with a special marker
- Procs and Methods are marked as unpersistable

During deserialization, these special markers are used to reconstruct the original objects.

### 4.3 Retry Logic

The event store implements exponential backoff retry logic to handle transient failures:
- Each operation is wrapped in a `with_retries` method
- The retry count and delay are configurable
- The delay increases with each retry attempt
- Failures are logged and metrics are updated

### 4.4 Metrics and Monitoring

The event store collects metrics about its operations:
- Number of events stored and loaded
- Number of snapshots stored and loaded
- Number of store and load failures
- Number of aggregates and event types

These metrics can be viewed using the event_store_stats.rb script.

### 4.5 Integration with Existing Code

The event sourcing system integrates with the existing code through several mechanisms:
- The Manager class initializes the event sourcing system and records events for player and object operations
- The StorageMachine class ensures that objects exist in the event store and provides a migration utility
- The GameObject class records attribute and container updates in the event store
- The Gary class provides access to event store statistics

## 5. Usage Examples

### 5.1 Creating a Game Object

```ruby
# Create a new game object
object = Aethyr::Core::Objects::GameObject.new

# The GameObject constructor will automatically record a creation event if event sourcing is enabled
# This is handled by the Manager#create_object method
```

### 5.2 Updating a Game Object Attribute

```ruby
# Update the long description of a game object
object.long_desc = "This is a new description"

# The long_desc= method will automatically record an update event if event sourcing is enabled
```

### 5.3 Moving a Game Object to a New Container

```ruby
# Move a game object to a new container
object.container = new_container.goid

# The container= method will automatically record a container update event if event sourcing is enabled
```

### 5.4 Creating a Player

```ruby
# Create a new player
player = Aethyr::Core::Objects::Player.new
$manager.add_player(player, "password")

# The Manager#add_player method will automatically record a player creation event if event sourcing is enabled
```

### 5.5 Updating a Player's Password

```ruby
# Update a player's password
$manager.set_password(player, "new_password")

# The Manager#set_password method will automatically record a password update event if event sourcing is enabled
```

### 5.6 Migrating Existing Data to the Event Store

```ruby
# Migrate existing data to the event store
$manager.storage.migrate_to_event_store
```

### 5.7 Viewing Event Store Statistics

```ruby
# View event store statistics
stats = $manager.event_store_stats
puts "Total events: #{stats[:events_stored]}"
```

## 6. Advanced Topics

### 6.1 Snapshots

Snapshots provide a performance optimization by caching the state of an aggregate at a specific sequence number. This reduces the number of events that need to be replayed when loading an aggregate.

The event store provides methods to store and load snapshots:
- `store_snapshot(aggregate_id, event)`: Stores a snapshot for an aggregate
- `load_snapshot(aggregate_id)`: Loads the most recent snapshot for an aggregate

### 6.2 Rebuilding World State

The event sourcing system can rebuild the world state from events, which is useful for recovering from crashes or verifying data consistency.

```ruby
# Rebuild world state from events
Aethyr::Core::EventSourcing::SequentSetup.rebuild_world_state
```

### 6.3 Handling Complex Objects

The event store includes special handling for complex objects that cannot be directly serialized:
- Sets are converted to arrays with a special marker
- Symbols are converted to strings with a special marker
- GameObject references are converted to GOIDs with a special marker
- Procs and Methods are marked as unpersistable

This ensures that events can be properly serialized and deserialized, even when they contain complex objects.

### 6.4 Fallback to File-Based Storage

The event store includes a fallback mechanism that uses the file system when ImmuDB is not available. This ensures that the event sourcing system can still function even if the database is unavailable.

```ruby
# The event store will automatically fall back to file-based storage if ImmuDB is not available
if @use_immudb
  # ImmuDB storage
else
  # File-based storage
end
```

## 7. Troubleshooting and Error Handling

### 7.1 Common Errors

#### 7.1.1 ImmuDB Connection Errors

If the event store cannot connect to ImmuDB, it will fall back to file-based storage and log a warning:

```
ImmuDB not available, using file-based event store: Cannot load immudb-ruby
```

#### 7.1.2 Event Store Operation Failures

If an event store operation fails after multiple retry attempts, it will log an error:

```
Event store operation failed after 3 attempts: Connection refused
```

#### 7.1.3 Missing Sequent Gem

If the Sequent gem is not available, the event sourcing system will be disabled and log a warning:

```
Event sourcing disabled: Cannot load sequent
```

### 7.2 Logging and Debugging

The event sourcing system includes comprehensive logging to help diagnose issues:
- Initialization and configuration are logged at Medium level
- Operation failures are logged at Medium level
- Persistent failures are logged at Ultimate level
- Detailed operation information is logged at Ultimate level

### 7.3 Recovery Strategies

#### 7.3.1 Rebuilding World State

If the in-memory state becomes inconsistent with the event store, you can rebuild the world state from events:

```ruby
Aethyr::Core::EventSourcing::SequentSetup.rebuild_world_state
```

#### 7.3.2 Migrating Data

If the event store is empty or incomplete, you can migrate existing data to the event store:

```ruby
$manager.storage.migrate_to_event_store
```

#### 7.3.3 Resetting the Event Store

In extreme cases, you can reset the event store and start fresh:

```ruby
Sequent.configuration.event_store.reset!
```

## 8. Future Enhancements

### 8.1 Event Versioning

The current implementation does not include explicit event versioning. Adding version information to events would allow for backward compatibility when event schemas change.

### 8.2 Event Upcasting

Event upcasting would allow for transforming old event versions into new versions during deserialization, ensuring that the system can handle events from different versions.

### 8.3 Event Sourcing for Additional Game Objects

The current implementation focuses on basic game objects, players, and rooms. Extending event sourcing to additional game objects, such as items, mobiles, and areas, would provide a more complete history of the game world.

### 8.4 Improved Projections

The current projections are basic and focus on recreating the original object structure. Adding specialized projections for specific query patterns would improve read performance and enable new features.

### 8.5 Event Replay and Analysis

Adding tools for replaying and analyzing events would enable advanced features such as:
- Time travel to see the state of the game world at any point in time
- Analysis of player behavior and game balance
- Debugging complex issues by examining the sequence of events

## 9. Conclusion

The Aethyr event sourcing system provides a robust, persistent record of all state changes in the game world. By recording each change as an immutable event, the system offers a complete history of the game world, the ability to reconstruct the state of any object at any point in time, and resilience against crashes and data corruption.

The implementation uses the Sequent framework for event sourcing and CQRS, with ImmuDB as the primary event store and a file-based fallback mechanism. It integrates with the existing game systems through the Manager, StorageMachine, and GameObject classes, providing a seamless transition from the traditional storage system to event sourcing.

The system includes comprehensive documentation, logging, and error handling, making it easy to understand, use, and troubleshoot. It also includes utilities for migrating existing data to the event store and viewing event store statistics.

Future enhancements could include event versioning, event upcasting, extending event sourcing to additional game objects, improving projections, and adding tools for event replay and analysis.
