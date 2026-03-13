# frozen_string_literal: true

###############################################################################
# Step definitions for Aethyr::Core::EventSourcing::Projections              #
#                                                                             #
# These tests exercise every `on` handler block in GameObjectProjector,      #
# PlayerProjector, and RoomProjector by injecting a lightweight mock         #
# persistor and sending real Sequent events through the projector.           #
###############################################################################
require 'test/unit/assertions'
require 'securerandom'
require 'ostruct'
require 'logger'

# Load Sequent and the projection code eagerly.
require 'sequent'
require 'aethyr/core/event_sourcing/events'
require 'aethyr/core/event_sourcing/projections'

# Capture references to classes NOW, before any test can remove_const :Sequent.
# Also capture the Sequent module itself so we can re-assign it later.
module ProjectionTestConstants
  SequentModule             = ::Sequent

  GameObjectProjector       = Aethyr::Core::EventSourcing::GameObjectProjector
  PlayerProjector           = Aethyr::Core::EventSourcing::PlayerProjector
  RoomProjector             = Aethyr::Core::EventSourcing::RoomProjector

  GameObjectCreated         = Aethyr::Core::EventSourcing::GameObjectCreated
  GameObjectAttributeUpdated  = Aethyr::Core::EventSourcing::GameObjectAttributeUpdated
  GameObjectAttributesUpdated = Aethyr::Core::EventSourcing::GameObjectAttributesUpdated
  GameObjectContainerUpdated  = Aethyr::Core::EventSourcing::GameObjectContainerUpdated
  GameObjectDeleted           = Aethyr::Core::EventSourcing::GameObjectDeleted
  PlayerCreated             = Aethyr::Core::EventSourcing::PlayerCreated
  PlayerPasswordUpdated     = Aethyr::Core::EventSourcing::PlayerPasswordUpdated
  PlayerAdminStatusUpdated  = Aethyr::Core::EventSourcing::PlayerAdminStatusUpdated
  RoomCreated               = Aethyr::Core::EventSourcing::RoomCreated
  RoomDescriptionUpdated    = Aethyr::Core::EventSourcing::RoomDescriptionUpdated
  RoomExitAdded             = Aethyr::Core::EventSourcing::RoomExitAdded
  RoomExitRemoved           = Aethyr::Core::EventSourcing::RoomExitRemoved

  SequentConfiguration = ::Sequent::Configuration
end

World(Test::Unit::Assertions)

# ---------------------------------------------------------------------------
# Mock persistor
# ---------------------------------------------------------------------------
class ProjectionMockPersistor
  attr_reader :created_records, :updated_records

  def initialize
    @created_records = []
    @updated_records = []
  end

  def create_record(table, attrs = {})
    @created_records << [table, attrs]
  end

  def update_all_records(table, where, updates)
    resolved = {}
    updates.each do |k, v|
      if v.respond_to?(:call)
        record = record_for(table, where)
        resolved[k] = v.call(record)
      else
        resolved[k] = v
      end
    end
    @updated_records << [table, where, resolved]
  end

  private

  def record_for(table, where)
    match = @created_records.reverse.detect { |t, attrs|
      t == table && where.all? { |k, v| attrs[k] == v }
    }
    if match
      OpenStruct.new(match[1])
    else
      OpenStruct.new(attributes: Marshal.dump({}), exits: Marshal.dump({}))
    end
  end
end

# ---------------------------------------------------------------------------
# Shared helpers
# ---------------------------------------------------------------------------
module ProjectionWorld
  attr_accessor :projector, :persistor, :aggregate_id

  def fresh_aggregate_id
    @aggregate_id = SecureRandom.uuid
  end

  def dispatch_to_projector(event)
    handlers = projector.class.message_router.match_message(event)
    handlers.each { |handler| projector.instance_exec(event, &handler) }
  end

  # Ensure the top-level Sequent constant exists and has a usable
  # configuration.  Other test files may remove_const :Sequent.
  def ensure_sequent!
    unless Object.const_defined?(:Sequent)
      Object.const_set(:Sequent, ProjectionTestConstants::SequentModule)
    end

    seq = ProjectionTestConstants::SequentModule
    begin
      cfg = seq.configuration
      cfg.strict_check_attributes_on_apply_events
    rescue => _e
      tmp = ProjectionTestConstants::SequentConfiguration.new
      tmp.strict_check_attributes_on_apply_events = false
      seq.instance_variable_set(:@configuration, tmp)
    end
  end

  def build_event(klass, **attrs)
    ensure_sequent!
    klass.new(attrs)
  end
end
World(ProjectionWorld)

# ===========================================================================
#  GameObjectProjector
# ===========================================================================

Given('a GameObjectProjector with a mock persistor') do
  self.persistor = ProjectionMockPersistor.new
  self.projector = ProjectionTestConstants::GameObjectProjector.new(persistor)
  fresh_aggregate_id
end

When('it receives a GameObjectCreated event') do
  event = build_event(
    ProjectionTestConstants::GameObjectCreated,
    aggregate_id: aggregate_id,
    sequence_number: 1,
    name: 'Sword',
    generic: 'weapon',
    container_id: 'room-1',
    attributes: { 'damage' => 10 }
  )
  dispatch_to_projector(event)
end

Then('a game_objects record should be created with the correct attributes') do
  assert_equal 1, persistor.created_records.size
  table, attrs = persistor.created_records.first
  assert_equal :game_objects, table
  assert_equal aggregate_id, attrs[:aggregate_id]
  assert_equal 'Sword', attrs[:name]
  assert_equal 'weapon', attrs[:generic]
  assert_equal 'room-1', attrs[:container_id]
  assert_equal false, attrs[:deleted]
  assert_equal({ 'damage' => 10 }, Marshal.load(attrs[:attributes]))
end

When('it receives a GameObjectAttributeUpdated event') do
  persistor.create_record(:game_objects,
    aggregate_id: aggregate_id,
    attributes: Marshal.dump({ 'hp' => 100 })
  )
  event = build_event(
    ProjectionTestConstants::GameObjectAttributeUpdated,
    aggregate_id: aggregate_id,
    sequence_number: 2,
    key: 'hp',
    value: '200'
  )
  dispatch_to_projector(event)
end

Then('the game_objects record attributes should be updated with the single attribute') do
  assert_equal 1, persistor.updated_records.size
  table, where, updates = persistor.updated_records.first
  assert_equal :game_objects, table
  assert_equal({ aggregate_id: aggregate_id }, where)
  merged = Marshal.load(updates[:attributes])
  assert_equal '200', merged['hp']
end

When('it receives a GameObjectAttributesUpdated event') do
  persistor.create_record(:game_objects,
    aggregate_id: aggregate_id,
    attributes: Marshal.dump({ 'hp' => 100 })
  )
  event = build_event(
    ProjectionTestConstants::GameObjectAttributesUpdated,
    aggregate_id: aggregate_id,
    sequence_number: 2,
    attributes: { 'hp' => 250, 'mp' => 50 }
  )
  dispatch_to_projector(event)
end

Then('the game_objects record attributes should be updated with the merged attributes') do
  assert_equal 1, persistor.updated_records.size
  table, where, updates = persistor.updated_records.first
  assert_equal :game_objects, table
  assert_equal({ aggregate_id: aggregate_id }, where)
  merged = Marshal.load(updates[:attributes])
  assert_equal 250, merged['hp']
  assert_equal 50, merged['mp']
end

When('it receives a GameObjectContainerUpdated event') do
  event = build_event(
    ProjectionTestConstants::GameObjectContainerUpdated,
    aggregate_id: aggregate_id,
    sequence_number: 2,
    container_id: 'chest-42'
  )
  dispatch_to_projector(event)
end

Then('the game_objects record container_id should be updated') do
  assert_equal 1, persistor.updated_records.size
  table, where, updates = persistor.updated_records.first
  assert_equal :game_objects, table
  assert_equal({ aggregate_id: aggregate_id }, where)
  assert_equal 'chest-42', updates[:container_id]
end

When('it receives a GameObjectDeleted event') do
  event = build_event(
    ProjectionTestConstants::GameObjectDeleted,
    aggregate_id: aggregate_id,
    sequence_number: 2
  )
  dispatch_to_projector(event)
end

Then('the game_objects record should be marked as deleted') do
  assert_equal 1, persistor.updated_records.size
  table, where, updates = persistor.updated_records.first
  assert_equal :game_objects, table
  assert_equal({ aggregate_id: aggregate_id }, where)
  assert_equal true, updates[:deleted]
end

# ===========================================================================
#  PlayerProjector
# ===========================================================================

Given('a PlayerProjector with a mock persistor') do
  self.persistor = ProjectionMockPersistor.new
  self.projector = ProjectionTestConstants::PlayerProjector.new(persistor)
  fresh_aggregate_id
end

When('it receives a PlayerCreated event') do
  event = build_event(
    ProjectionTestConstants::PlayerCreated,
    aggregate_id: aggregate_id,
    sequence_number: 1,
    password_hash: 'abc123hash',
    admin: false
  )
  dispatch_to_projector(event)
end

Then('a players record should be created with the correct player attributes') do
  assert_equal 1, persistor.created_records.size
  table, attrs = persistor.created_records.first
  assert_equal :players, table
  assert_equal aggregate_id, attrs[:aggregate_id]
  assert_equal 'abc123hash', attrs[:password_hash]
  assert_equal false, attrs[:admin]
end

When('it receives a PlayerPasswordUpdated event') do
  event = build_event(
    ProjectionTestConstants::PlayerPasswordUpdated,
    aggregate_id: aggregate_id,
    sequence_number: 2,
    password_hash: 'newhash456'
  )
  dispatch_to_projector(event)
end

Then('the players record password_hash should be updated') do
  assert_equal 1, persistor.updated_records.size
  table, where, updates = persistor.updated_records.first
  assert_equal :players, table
  assert_equal({ aggregate_id: aggregate_id }, where)
  assert_equal 'newhash456', updates[:password_hash]
end

When('it receives a PlayerAdminStatusUpdated event') do
  event = build_event(
    ProjectionTestConstants::PlayerAdminStatusUpdated,
    aggregate_id: aggregate_id,
    sequence_number: 2,
    admin: true
  )
  dispatch_to_projector(event)
end

Then('the players record admin status should be updated') do
  assert_equal 1, persistor.updated_records.size
  table, where, updates = persistor.updated_records.first
  assert_equal :players, table
  assert_equal({ aggregate_id: aggregate_id }, where)
  assert_equal true, updates[:admin]
end

# ===========================================================================
#  RoomProjector
# ===========================================================================

Given('a RoomProjector with a mock persistor') do
  self.persistor = ProjectionMockPersistor.new
  self.projector = ProjectionTestConstants::RoomProjector.new(persistor)
  fresh_aggregate_id
end

When('it receives a RoomCreated event') do
  event = build_event(
    ProjectionTestConstants::RoomCreated,
    aggregate_id: aggregate_id,
    sequence_number: 1,
    description: 'A dark cave',
    exits: { 'north' => 'room-2' }
  )
  dispatch_to_projector(event)
end

Then('a rooms record should be created with the correct room attributes') do
  assert_equal 1, persistor.created_records.size
  table, attrs = persistor.created_records.first
  assert_equal :rooms, table
  assert_equal aggregate_id, attrs[:aggregate_id]
  assert_equal 'A dark cave', attrs[:description]
  assert_equal({ 'north' => 'room-2' }, Marshal.load(attrs[:exits]))
end

When('it receives a RoomDescriptionUpdated event') do
  event = build_event(
    ProjectionTestConstants::RoomDescriptionUpdated,
    aggregate_id: aggregate_id,
    sequence_number: 2,
    description: 'A well-lit hall'
  )
  dispatch_to_projector(event)
end

Then('the rooms record description should be updated') do
  assert_equal 1, persistor.updated_records.size
  table, where, updates = persistor.updated_records.first
  assert_equal :rooms, table
  assert_equal({ aggregate_id: aggregate_id }, where)
  assert_equal 'A well-lit hall', updates[:description]
end

When('it receives a RoomExitAdded event') do
  persistor.create_record(:rooms,
    aggregate_id: aggregate_id,
    exits: Marshal.dump({ 'north' => 'room-2' })
  )
  event = build_event(
    ProjectionTestConstants::RoomExitAdded,
    aggregate_id: aggregate_id,
    sequence_number: 2,
    direction: 'south',
    target_room_id: 'room-3'
  )
  dispatch_to_projector(event)
end

Then('the rooms record exits should include the new exit') do
  assert_equal 1, persistor.updated_records.size
  table, where, updates = persistor.updated_records.first
  assert_equal :rooms, table
  assert_equal({ aggregate_id: aggregate_id }, where)
  exits = Marshal.load(updates[:exits])
  assert_equal 'room-2', exits['north']
  assert_equal 'room-3', exits['south']
end

When('it receives a RoomExitRemoved event') do
  persistor.create_record(:rooms,
    aggregate_id: aggregate_id,
    exits: Marshal.dump({ 'north' => 'room-2', 'south' => 'room-3' })
  )
  event = build_event(
    ProjectionTestConstants::RoomExitRemoved,
    aggregate_id: aggregate_id,
    sequence_number: 2,
    direction: 'south'
  )
  dispatch_to_projector(event)
end

Then('the rooms record exits should not include the removed direction') do
  assert_equal 1, persistor.updated_records.size
  table, where, updates = persistor.updated_records.first
  assert_equal :rooms, table
  assert_equal({ aggregate_id: aggregate_id }, where)
  exits = Marshal.load(updates[:exits])
  assert_equal({ 'north' => 'room-2' }, exits)
  assert_nil exits['south']
end
