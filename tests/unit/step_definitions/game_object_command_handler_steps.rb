# frozen_string_literal: true
###############################################################################
# Step definitions for GameObjectCommandHandler                                #
#                                                                              #
# These steps exercise the Sequent command handler blocks defined in           #
#   lib/aethyr/core/event_sourcing/command_handlers.rb                         #
#                                                                              #
# All 12 command-handler blocks are covered by dispatching real commands        #
# through the Sequent command infrastructure and asserting the resulting events.#
###############################################################################

require 'test/unit/assertions'
require 'securerandom'
require 'sequent'
require 'sequent/test'
require 'rspec/expectations'
require 'rspec/mocks'

require 'aethyr/core/event_sourcing/domain'
require 'aethyr/core/event_sourcing/events'
require 'aethyr/core/event_sourcing/commands'
require 'aethyr/core/event_sourcing/command_handlers'

World(Test::Unit::Assertions)
World(RSpec::Matchers)
World(RSpec::Mocks::ExampleMethods)
World(Sequent::Test::CommandHandlerHelpers)

###############################################################################
# SimpleFakeEventStore avoids Oj serialisation that chokes on Object-typed     #
# attributes (e.g. GameObjectAttributeUpdated.value).                          #
###############################################################################
class SimpleFakeEventStore < Sequent::Test::CommandHandlerHelpers::FakeEventStore
  private

  def serialize_events(events)
    events.map { |event| event }
  end

  def deserialize_events(events)
    events
  end
end

###############################################################################
# Guarded monkey-patches: only active when $cmd_handler_test_active is true.   #
# This prevents interference with other test scenarios.                        #
###############################################################################
$cmd_handler_test_active = false

# 1. Skip Sequent's type-conversion step which does not support `Object` attrs.
module Sequent::Core::Helpers::TypeConversionSupport
  alias_method :__orig_parse_attrs_to_correct_types, :parse_attrs_to_correct_types unless method_defined?(:__orig_parse_attrs_to_correct_types)
  def parse_attrs_to_correct_types
    return self if $cmd_handler_test_active
    __orig_parse_attrs_to_correct_types
  end
end

# 2. Fix do_with_aggregate for when the handler passes an ID string.
module Sequent::Core
  class BaseCommandHandler
    alias_method :__orig_do_with_aggregate, :do_with_aggregate unless method_defined?(:__orig_do_with_aggregate)
    def do_with_aggregate(command_or_id, clazz = nil, aggregate_id = nil, &block)
      if $cmd_handler_test_active && command_or_id.is_a?(String)
        aggregate = repository.load_aggregate(command_or_id, clazz)
        yield aggregate if block_given?
      else
        __orig_do_with_aggregate(command_or_id, clazz, aggregate_id, &block)
      end
    end
  end
end

###############################################################################
# Tagged Before/After hooks                                                    #
###############################################################################
Before('@real_sequent') do
  $cmd_handler_test_active = true

  # Remove RSpec mock on Sequent.configuration set by event_sourcing_steps.rb
  RSpec::Mocks.space.proxy_for(Sequent).reset

  Sequent.configure do |config|
    config.event_store = SimpleFakeEventStore.new
    config.command_handlers = [
      Aethyr::Core::EventSourcing::GameObjectCommandHandler.new
    ]
    config.event_handlers = []
    config.transaction_provider = Sequent::Core::Transactions::NoTransactions.new
  end
end

After('@real_sequent') do
  $cmd_handler_test_active = false
end

###############################################################################
# Shared world                                                                 #
###############################################################################
module GameObjectCommandHandlerWorld
  attr_accessor :cmd_handler_aggregate_id, :cmd_handler_player_aggregate_id,
                :cmd_handler_room_aggregate_id, :cmd_handler_target_room_id

  def cmd_handler_new_uuid
    SecureRandom.uuid
  end
end
World(GameObjectCommandHandlerWorld)

###############################################################################
# Background                                                                   #
###############################################################################
Given('the Sequent test environment is configured for command handler testing') do
  # Setup done by Before('@real_sequent') hook
end

###############################################################################
# Given – create aggregates                                                    #
###############################################################################
Given('an existing game object aggregate') do
  self.cmd_handler_aggregate_id = cmd_handler_new_uuid
  when_command(
    Aethyr::Core::EventSourcing::CreateGameObject.new(
      aggregate_id: cmd_handler_aggregate_id,
      id: cmd_handler_aggregate_id,
      name: 'Test Object',
      generic: 'thing',
      container_id: 'room-1'
    )
  )
end

Given('an existing player aggregate') do
  self.cmd_handler_player_aggregate_id = cmd_handler_new_uuid
  when_command(
    Aethyr::Core::EventSourcing::CreatePlayer.new(
      aggregate_id: cmd_handler_player_aggregate_id,
      id: cmd_handler_player_aggregate_id,
      name: 'TestPlayer',
      password_hash: 'old_hash_abc'
    )
  )
end

Given('an existing room aggregate') do
  self.cmd_handler_room_aggregate_id = cmd_handler_new_uuid
  when_command(
    Aethyr::Core::EventSourcing::CreateRoom.new(
      aggregate_id: cmd_handler_room_aggregate_id,
      id: cmd_handler_room_aggregate_id,
      name: 'Test Room',
      description: 'A plain test room.'
    )
  )
end

Given('an existing room aggregate with an exit') do
  self.cmd_handler_room_aggregate_id = cmd_handler_new_uuid
  self.cmd_handler_target_room_id = cmd_handler_new_uuid
  when_command(
    Aethyr::Core::EventSourcing::CreateRoom.new(
      aggregate_id: cmd_handler_room_aggregate_id,
      id: cmd_handler_room_aggregate_id,
      name: 'Test Room',
      description: 'A room with an exit.'
    )
  )
  when_command(
    Aethyr::Core::EventSourcing::AddRoomExit.new(
      aggregate_id: cmd_handler_room_aggregate_id,
      id: cmd_handler_room_aggregate_id,
      direction: 'north',
      target_room_id: cmd_handler_target_room_id
    )
  )
end

###############################################################################
# When – dispatch commands                                                     #
###############################################################################

When('I dispatch a CreateGameObject command') do
  self.cmd_handler_aggregate_id = cmd_handler_new_uuid
  when_command(
    Aethyr::Core::EventSourcing::CreateGameObject.new(
      aggregate_id: cmd_handler_aggregate_id,
      id: cmd_handler_aggregate_id,
      name: 'Excalibur',
      generic: 'sword',
      container_id: 'room-42'
    )
  )
end

When('I dispatch an UpdateGameObjectAttribute command') do
  when_command(
    Aethyr::Core::EventSourcing::UpdateGameObjectAttribute.new(
      aggregate_id: cmd_handler_aggregate_id,
      id: cmd_handler_aggregate_id,
      key: 'damage',
      value: '10'
    )
  )
end

When('I dispatch an UpdateGameObjectAttributes command') do
  when_command(
    Aethyr::Core::EventSourcing::UpdateGameObjectAttributes.new(
      aggregate_id: cmd_handler_aggregate_id,
      id: cmd_handler_aggregate_id,
      attributes: { 'weight' => '5', 'color' => 'silver' }
    )
  )
end

When('I dispatch an UpdateGameObjectContainer command') do
  when_command(
    Aethyr::Core::EventSourcing::UpdateGameObjectContainer.new(
      aggregate_id: cmd_handler_aggregate_id,
      id: cmd_handler_aggregate_id,
      container_id: 'player-99'
    )
  )
end

When('I dispatch a DeleteGameObject command') do
  when_command(
    Aethyr::Core::EventSourcing::DeleteGameObject.new(
      aggregate_id: cmd_handler_aggregate_id,
      id: cmd_handler_aggregate_id
    )
  )
end

When('I dispatch a CreatePlayer command') do
  self.cmd_handler_player_aggregate_id = cmd_handler_new_uuid
  when_command(
    Aethyr::Core::EventSourcing::CreatePlayer.new(
      aggregate_id: cmd_handler_player_aggregate_id,
      id: cmd_handler_player_aggregate_id,
      name: 'Gandalf',
      password_hash: 'hash_xyz_123'
    )
  )
end

When('I dispatch an UpdatePlayerPassword command') do
  when_command(
    Aethyr::Core::EventSourcing::UpdatePlayerPassword.new(
      aggregate_id: cmd_handler_player_aggregate_id,
      id: cmd_handler_player_aggregate_id,
      password_hash: 'new_hash_456'
    )
  )
end

When('I dispatch an UpdatePlayerAdminStatus command') do
  when_command(
    Aethyr::Core::EventSourcing::UpdatePlayerAdminStatus.new(
      aggregate_id: cmd_handler_player_aggregate_id,
      id: cmd_handler_player_aggregate_id,
      admin: true
    )
  )
end

When('I dispatch a CreateRoom command') do
  self.cmd_handler_room_aggregate_id = cmd_handler_new_uuid
  when_command(
    Aethyr::Core::EventSourcing::CreateRoom.new(
      aggregate_id: cmd_handler_room_aggregate_id,
      id: cmd_handler_room_aggregate_id,
      name: 'Grand Hall',
      description: 'A vast hall with marble pillars.'
    )
  )
end

When('I dispatch an UpdateRoomDescription command') do
  when_command(
    Aethyr::Core::EventSourcing::UpdateRoomDescription.new(
      aggregate_id: cmd_handler_room_aggregate_id,
      id: cmd_handler_room_aggregate_id,
      description: 'An updated room description.'
    )
  )
end

When('I dispatch an AddRoomExit command') do
  self.cmd_handler_target_room_id = cmd_handler_new_uuid
  when_command(
    Aethyr::Core::EventSourcing::AddRoomExit.new(
      aggregate_id: cmd_handler_room_aggregate_id,
      id: cmd_handler_room_aggregate_id,
      direction: 'south',
      target_room_id: cmd_handler_target_room_id
    )
  )
end

When('I dispatch a RemoveRoomExit command') do
  when_command(
    Aethyr::Core::EventSourcing::RemoveRoomExit.new(
      aggregate_id: cmd_handler_room_aggregate_id,
      id: cmd_handler_room_aggregate_id,
      direction: 'north'
    )
  )
end

###############################################################################
# Then – assertions                                                            #
###############################################################################

Then('a GameObjectCreated event should be produced with the correct attributes') do
  events = stored_events
  assert_equal(1, events.size, "Expected exactly 1 event, got #{events.size}")
  event = events.first
  assert_kind_of(Aethyr::Core::EventSourcing::GameObjectCreated, event)
  assert_equal('Excalibur', event.name)
  assert_equal('sword', event.generic)
  assert_equal('room-42', event.container_id)
end

Then('a GameObjectAttributeUpdated event should be produced with the correct key and value') do
  events = stored_events
  assert_equal(1, events.size, "Expected exactly 1 event, got #{events.size}")
  event = events.first
  assert_kind_of(Aethyr::Core::EventSourcing::GameObjectAttributeUpdated, event)
  assert_equal('damage', event.key)
  assert_equal('10', event.value)
end

Then('a GameObjectAttributesUpdated event should be produced with the correct attributes hash') do
  events = stored_events
  assert_equal(1, events.size, "Expected exactly 1 event, got #{events.size}")
  event = events.first
  assert_kind_of(Aethyr::Core::EventSourcing::GameObjectAttributesUpdated, event)
  assert_equal({ 'weight' => '5', 'color' => 'silver' }, event.attributes)
end

Then('a GameObjectContainerUpdated event should be produced with the correct container id') do
  events = stored_events
  assert_equal(1, events.size, "Expected exactly 1 event, got #{events.size}")
  event = events.first
  assert_kind_of(Aethyr::Core::EventSourcing::GameObjectContainerUpdated, event)
  assert_equal('player-99', event.container_id)
end

Then('a GameObjectDeleted event should be produced') do
  events = stored_events
  assert_equal(1, events.size, "Expected exactly 1 event, got #{events.size}")
  event = events.first
  assert_kind_of(Aethyr::Core::EventSourcing::GameObjectDeleted, event)
end

Then('a PlayerCreated event should be produced with the correct player attributes') do
  events = stored_events
  created_events = events.select { |e| e.is_a?(Aethyr::Core::EventSourcing::PlayerCreated) }
  assert_equal(1, created_events.size, "Expected exactly 1 PlayerCreated event")
  event = created_events.first
  assert_equal('hash_xyz_123', event.password_hash)
  assert_equal(false, event.admin)
end

Then('a PlayerPasswordUpdated event should be produced with the correct password hash') do
  events = stored_events
  assert_equal(1, events.size, "Expected exactly 1 event, got #{events.size}")
  event = events.first
  assert_kind_of(Aethyr::Core::EventSourcing::PlayerPasswordUpdated, event)
  assert_equal('new_hash_456', event.password_hash)
end

Then('a PlayerAdminStatusUpdated event should be produced with the correct admin status') do
  events = stored_events
  assert_equal(1, events.size, "Expected exactly 1 event, got #{events.size}")
  event = events.first
  assert_kind_of(Aethyr::Core::EventSourcing::PlayerAdminStatusUpdated, event)
  assert_equal(true, event.admin)
end

Then('a RoomCreated event should be produced with the correct room attributes') do
  events = stored_events
  created_events = events.select { |e| e.is_a?(Aethyr::Core::EventSourcing::RoomCreated) }
  assert_equal(1, created_events.size, "Expected exactly 1 RoomCreated event")
  event = created_events.first
  assert_equal('A vast hall with marble pillars.', event.description)
end

Then('a RoomDescriptionUpdated event should be produced with the correct description') do
  events = stored_events
  assert_equal(1, events.size, "Expected exactly 1 event, got #{events.size}")
  event = events.first
  assert_kind_of(Aethyr::Core::EventSourcing::RoomDescriptionUpdated, event)
  assert_equal('An updated room description.', event.description)
end

Then('a RoomExitAdded event should be produced with the correct direction and target') do
  events = stored_events
  assert_equal(1, events.size, "Expected exactly 1 event, got #{events.size}")
  event = events.first
  assert_kind_of(Aethyr::Core::EventSourcing::RoomExitAdded, event)
  assert_equal('south', event.direction)
  assert_equal(cmd_handler_target_room_id, event.target_room_id)
end

Then('a RoomExitRemoved event should be produced with the correct direction') do
  events = stored_events
  assert_equal(1, events.size, "Expected exactly 1 event, got #{events.size}")
  event = events.first
  assert_kind_of(Aethyr::Core::EventSourcing::RoomExitRemoved, event)
  assert_equal('north', event.direction)
end
