# frozen_string_literal: true

# =============================================================================
# Step definitions for Event Sourcing Domain Aggregate Roots
# =============================================================================
# These steps exercise the Sequent aggregate root classes defined in
# lib/aethyr/core/event_sourcing/domain.rb, covering GameObject, Player,
# and Room initialization, command methods, and event handler state changes.
# =============================================================================

require 'sequent'
require 'aethyr/core/event_sourcing/events'
require 'aethyr/core/event_sourcing/domain'
require 'test/unit/assertions'

World(Test::Unit::Assertions)

# Convenience alias for the Domain module
DomainModule = Aethyr::Core::EventSourcing::Domain

# ---------------------------------------------------------------------------
# Helper to restore the real Sequent configuration.
#
# Other step definition files (e.g. event_sourcing_steps.rb) install untagged
# Before hooks that mock Sequent.configuration with an RSpec double.  The mock
# is baked directly into the singleton class by RSpec and survives proxy.reset
# and even RSpec::Mocks.teardown.  The only reliable way to restore the real
# configuration is to redefine the singleton method.
# ---------------------------------------------------------------------------
module DomainSetupHelper
  def ensure_real_sequent_configuration!
    # Restore the real Sequent.configuration method if it has been mocked.
    config_is_mock = begin; Sequent.configuration.is_a?(RSpec::Mocks::Double); rescue; false; end
    if config_is_mock
      Sequent.define_singleton_method(:configuration) do
        Sequent::Configuration.instance
      end
      Sequent.define_singleton_method(:configure) do |&block|
        Sequent::Configuration.reset
        block.call(Sequent::Configuration.instance)
        Sequent::Configuration.instance.autoregister!
      end
    end

    Sequent.configure do |config|
      config.event_store = nil
    end
  end
end
World(DomainSetupHelper)

# ---------------------------------------------------------------------------
# GameObject steps
# ---------------------------------------------------------------------------
When('I create a domain GameObject with id {string} name {string} generic {string} and container {string}') do |id, name, generic, container|
  ensure_real_sequent_configuration!
  @domain_object = DomainModule::GameObject.new(id, name, generic, container)
end

When('I create a domain GameObject with id {string} name {string} generic {string} and no container') do |id, name, generic|
  ensure_real_sequent_configuration!
  @domain_object = DomainModule::GameObject.new(id, name, generic)
end

Given('a domain GameObject with id {string} name {string} generic {string} and container {string}') do |id, name, generic, container|
  ensure_real_sequent_configuration!
  @domain_object = DomainModule::GameObject.new(id, name, generic, container)
end

Then('the domain GameObject name should be {string}') do |expected|
  assert_equal expected, @domain_object.name
end

Then('the domain GameObject generic should be {string}') do |expected|
  assert_equal expected, @domain_object.generic
end

Then('the domain GameObject container_id should be {string}') do |expected|
  assert_equal expected, @domain_object.container_id
end

Then('the domain GameObject container_id should be nil') do
  assert_nil @domain_object.container_id
end

Then('the domain GameObject attributes should be an empty hash') do
  assert_equal({}, @domain_object.attributes)
end

Then('the domain GameObject should not be deleted') do
  assert_equal false, @domain_object.deleted?
end

Then('the domain GameObject should be deleted') do
  assert_equal true, @domain_object.deleted?
end

Then('the domain GameObject should have {int} uncommitted event(s)') do |count|
  assert_equal count, @domain_object.uncommitted_events.size
end

Then('the domain GameObject uncommitted event {int} should be a GameObjectCreated') do |index|
  event = @domain_object.uncommitted_events[index - 1]
  assert_instance_of Aethyr::Core::EventSourcing::GameObjectCreated, event
end

When('I update the domain GameObject attribute {string} to {string}') do |key, value|
  @domain_object.update_attribute(key, value)
end

Then('the domain GameObject attributes should include {string} with value {string}') do |key, value|
  assert_equal value, @domain_object.attributes[key]
end

When('I update the domain GameObject attributes with {string} as {string} and {string} as {string}') do |key1, val1, key2, val2|
  @domain_object.update_attributes({ key1 => val1, key2 => val2 })
end

When('I update the domain GameObject container to {string}') do |container_id|
  @domain_object.update_container(container_id)
end

When('I delete the domain GameObject') do
  @domain_object.delete
end

# ---------------------------------------------------------------------------
# Player steps
# ---------------------------------------------------------------------------
When('I create a domain Player with id {string} name {string} and password_hash {string}') do |id, name, pw_hash|
  ensure_real_sequent_configuration!
  @domain_player = DomainModule::Player.new(id, name, pw_hash)
  @domain_object = @domain_player
end

Given('a domain Player with id {string} name {string} and password_hash {string}') do |id, name, pw_hash|
  ensure_real_sequent_configuration!
  @domain_player = DomainModule::Player.new(id, name, pw_hash)
  @domain_object = @domain_player
end

Then('the domain Player password_hash should be {string}') do |expected|
  assert_equal expected, @domain_player.password_hash
end

Then('the domain Player admin should be false') do
  assert_equal false, @domain_player.admin
end

Then('the domain Player admin should be true') do
  assert_equal true, @domain_player.admin
end

Then('the domain Player should have {int} uncommitted events') do |count|
  assert_equal count, @domain_player.uncommitted_events.size
end

Then('the domain Player first uncommitted event should be a GameObjectCreated') do
  event = @domain_player.uncommitted_events[0]
  assert_instance_of Aethyr::Core::EventSourcing::GameObjectCreated, event
end

Then('the domain Player second uncommitted event should be a PlayerCreated') do
  event = @domain_player.uncommitted_events[1]
  assert_instance_of Aethyr::Core::EventSourcing::PlayerCreated, event
end

When('I set the domain Player password to {string}') do |pw_hash|
  @domain_player.set_password(pw_hash)
end

When('I set the domain Player admin to true') do
  @domain_player.set_admin(true)
end

When('I set the domain Player admin to false') do
  @domain_player.set_admin(false)
end

# ---------------------------------------------------------------------------
# Room steps
# ---------------------------------------------------------------------------
When('I create a domain Room with id {string} name {string} and description {string}') do |id, name, desc|
  ensure_real_sequent_configuration!
  @domain_room = DomainModule::Room.new(id, name, desc)
  @domain_object = @domain_room
end

Given('a domain Room with id {string} name {string} and description {string}') do |id, name, desc|
  ensure_real_sequent_configuration!
  @domain_room = DomainModule::Room.new(id, name, desc)
  @domain_object = @domain_room
end

Then('the domain Room description should be {string}') do |expected|
  assert_equal expected, @domain_room.description
end

Then('the domain Room exits should be an empty hash') do
  assert_equal({}, @domain_room.exits)
end

Then('the domain Room should have {int} uncommitted events') do |count|
  assert_equal count, @domain_room.uncommitted_events.size
end

Then('the domain Room first uncommitted event should be a GameObjectCreated') do
  event = @domain_room.uncommitted_events[0]
  assert_instance_of Aethyr::Core::EventSourcing::GameObjectCreated, event
end

Then('the domain Room second uncommitted event should be a RoomCreated') do
  event = @domain_room.uncommitted_events[1]
  assert_instance_of Aethyr::Core::EventSourcing::RoomCreated, event
end

When('I update the domain Room description to {string}') do |desc|
  @domain_room.update_description(desc)
end

When('I add a domain Room exit {string} to {string}') do |direction, target_id|
  @domain_room.add_exit(direction, target_id)
end

When('I remove the domain Room exit {string}') do |direction|
  @domain_room.remove_exit(direction)
end

Then('the domain Room exits should include {string} pointing to {string}') do |direction, target_id|
  assert_equal target_id, @domain_room.exits[direction]
end

Then('the domain Room exits should not include {string}') do |direction|
  assert_nil @domain_room.exits[direction]
end
