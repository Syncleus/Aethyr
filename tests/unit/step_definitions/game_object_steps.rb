# frozen_string_literal: true
###############################################################################
# Step definitions for GameObject base class feature.                          #
###############################################################################

require 'test/unit/assertions'
require 'aethyr/core/util/config'
ServerConfig[:log_level] ||= 0
require 'aethyr/core/objects/game_object'
require 'aethyr/core/objects/info/flags/flag'
require 'aethyr/core/event'
require 'aethyr/core/objects/reactor'
require 'aethyr/core/objects/traits/reacts'

World(Test::Unit::Assertions)

###############################################################################
# Shared state                                                                 #
###############################################################################
module GameObjectWorld
  attr_accessor :game_obj, :method_missing_result, :reacting_obj
end
World(GameObjectWorld)

###############################################################################
# Lightweight test doubles                                                     #
###############################################################################

# Minimal $manager stub that always says the goid does not exist yet.
class GOTestManager
  def existing_goid?(_goid)
    false
  end

  def get_object(_id)
    nil
  end
end

# A simple stand-in for an attribute.  Two instances are == only when they
# are the exact same object (Ruby default), which lets us test the
# non-matching detach branch.
class FakeAttribute
  def initialize(label)
    @label = label
  end
end

###############################################################################
# Before hook – ensure $manager is stubbed for every scenario                  #
###############################################################################
Before('@game_object_test') do
  $manager = GOTestManager.new
end

# Tag-less Before: set $manager if it's nil (safe fallback)
Before do
  $manager ||= GOTestManager.new
end

###############################################################################
# Given steps                                                                  #
###############################################################################

Given('a base GameObject with sex {string}') do |sex|
  self.game_obj = Aethyr::Core::Objects::GameObject.new(nil, nil, "thing", [], "short", "", "generic", sex, "a")
end

Given('a base GameObject with defaults') do
  self.game_obj = Aethyr::Core::Objects::GameObject.new(nil, nil, "thing", [], "A short desc.", "", "widget", "n", "a")
end

Given('a base GameObject with generic {string}') do |generic|
  self.game_obj = Aethyr::Core::Objects::GameObject.new(nil, nil, "thing", [], "short", "", generic, "n", "a")
  # Ensure @plural is nil so the generic branch is hit
  game_obj.instance_variable_set(:@plural, nil)
end

Given('a base GameObject with name {string} and nil generic') do |name|
  self.game_obj = Aethyr::Core::Objects::GameObject.new(nil, nil, name, [], "short", "", nil, "n", "a")
  game_obj.instance_variable_set(:@generic, nil)
  game_obj.instance_variable_set(:@plural, nil)
end

Given('a base GameObject with no name and no generic') do
  self.game_obj = Aethyr::Core::Objects::GameObject.new(nil, nil, "", [], "short", "", nil, "n", "a")
  game_obj.instance_variable_set(:@generic, nil)
  game_obj.instance_variable_set(:@name, nil)
  game_obj.instance_variable_set(:@plural, nil)
end

Given('a base GameObject with name {string}') do |name|
  self.game_obj = Aethyr::Core::Objects::GameObject.new(nil, nil, name, [], "short", "", "generic", "n", "a")
end

Given('a base GameObject with name {string} and alt_name {string}') do |name, alt|
  self.game_obj = Aethyr::Core::Objects::GameObject.new(nil, nil, name, [alt], "short", "", "generic", "n", "a")
end

Given('a base GameObject with name {string} and generic {string}') do |name, generic|
  self.game_obj = Aethyr::Core::Objects::GameObject.new(nil, nil, name, [], "short", "", generic, "n", "a")
end

Given('a base GameObject with empty long_desc') do
  self.game_obj = Aethyr::Core::Objects::GameObject.new(nil, nil, "thing", [], "Fallback short.", "", "generic", "n", "a")
end

Given('a base GameObject with long_desc {string}') do |desc|
  self.game_obj = Aethyr::Core::Objects::GameObject.new(nil, nil, "thing", [], "short", desc, "generic", "n", "a")
end

Given('a base GameObject with empty name and generic {string} and article {string}') do |generic, article|
  self.game_obj = Aethyr::Core::Objects::GameObject.new(nil, nil, "", [], "short", "", generic, "n", article)
end

Given('I attach a test attribute instance to the game object') do
  @test_attr = FakeAttribute.new("test")
  game_obj.attach_attribute(@test_attr)
end

Given('the game object is marked busy') do
  game_obj.instance_variable_set(:@busy, true)
end

Given('the game object plural is set to {string}') do |val|
  game_obj.plural = val
end

Given('the game object has a custom entrance message {string}') do |msg|
  game_obj.info.entrance_message = msg
end

Given('the game object has a custom exit message {string}') do |msg|
  game_obj.info.exit_message = msg
end

Given('game object event sourcing is enabled') do
  # Define ServerConfig if not present, enable event sourcing
  unless defined?(::ServerConfig)
    Object.const_set(:ServerConfig, {})
  end
  ServerConfig[:event_sourcing_enabled] = true

  # Define a minimal Sequent module so the code enters the event sourcing branch
  unless defined?(::Sequent)
    sequent_mod = Module.new do
      def self.command_service
        # Return an object whose execute_commands raises, exercising the rescue
        obj = Object.new
        def obj.execute_commands(*_args)
          raise "Stub: no real event store"
        end
        obj
      end
    end
    Object.const_set(:Sequent, sequent_mod)
  end

  # Also define the command classes if they don't exist
  unless defined?(Aethyr::Core::EventSourcing::UpdateGameObjectAttribute)
    mod = Aethyr::Core
    unless defined?(Aethyr::Core::EventSourcing)
      mod.const_set(:EventSourcing, Module.new)
    end
    es = Aethyr::Core::EventSourcing
    unless defined?(Aethyr::Core::EventSourcing::UpdateGameObjectAttribute)
      es.const_set(:UpdateGameObjectAttribute, Struct.new(:id, :key, :value, keyword_init: true))
    end
    unless defined?(Aethyr::Core::EventSourcing::UpdateGameObjectContainer)
      es.const_set(:UpdateGameObjectContainer, Struct.new(:id, :container_id, keyword_init: true))
    end
    unless defined?(Aethyr::Core::EventSourcing::UpdateGameObjectAttributes)
      es.const_set(:UpdateGameObjectAttributes, Struct.new(:id, :attributes, keyword_init: true))
    end
  end
end

Given('a base GameObject that includes Reacts') do
  require 'aethyr/core/objects/traits/reacts'

  # Build a one-off subclass that includes Reacts so self.is_a?(Reacts) is true
  klass = Class.new(Aethyr::Core::Objects::GameObject) do
    include Reacts
  end
  self.reacting_obj = klass.new(nil, nil, "reactor", [], "short", "", "generic", "n", "a")
end

###############################################################################
# When steps                                                                   #
###############################################################################

When('I detach the attribute by its class') do
  game_obj.detach_attribute(FakeAttribute)
end

When('I detach the attribute by its matching instance') do
  game_obj.detach_attribute(@test_attr)
end

When('I detach the attribute by a non-matching instance') do
  different = FakeAttribute.new("other")
  game_obj.detach_attribute(different)
end

When('I add a test flag with id {int} to the game object') do |id|
  @test_flag = Flag.new("strength", id, "buff", "increases strength", "a strength buff")
  game_obj.add_flag(@test_flag)
end

When('I call update on the game object') do
  game_obj.update
end

When('I call update on the reacting game object') do
  reacting_obj.update
end

When('I call alert on the game object') do
  game_obj.alert(Event.new(:Generic, action: :test))
end

When('I call an undefined method on the game object') do
  self.method_missing_result = game_obj.this_method_does_not_exist
end

When('I set the game object long_desc to {string}') do |desc|
  game_obj.long_desc = desc
end

When('I set the game object container to {string}') do |cid|
  game_obj.container = cid
end

When('I update attributes with name {string} and movable true') do |name|
  game_obj.update_attributes({ "name" => name, "movable" => true })
end

###############################################################################
# Then steps                                                                   #
###############################################################################

Then('the game object gender should be masculine') do
  assert_equal(Lexicon::Gender::MASCULINE, game_obj.gender)
end

Then('the game object gender should be feminine') do
  assert_equal(Lexicon::Gender::FEMININE, game_obj.gender)
end

Then('the game object gender should be neuter') do
  assert_equal(Lexicon::Gender::NEUTER, game_obj.gender)
end

Then('the game object should have no attributes') do
  assert(game_obj.attributes.empty?, "Expected no attributes but got: #{game_obj.attributes.inspect}")
end

Then('the game object should still have one attribute') do
  assert_equal(1, game_obj.attributes.size, "Expected exactly one attribute")
end

Then('the game object flags should be a Hash') do
  assert_kind_of(Hash, game_obj.flags)
end

Then('the game object info flags should contain id {int}') do |id|
  assert(game_obj.info.flags.key?(id), "Expected info.flags to contain key #{id}")
end

Then('the game object should still be busy') do
  assert(game_obj.busy?, "Expected game object to be busy")
end

Then('the game object should not be busy') do
  assert(!game_obj.busy?, "Expected game object to not be busy")
end

Then('the reacting game object should not be busy') do
  assert(!reacting_obj.busy?, "Expected reacting game object to not be busy after update")
end

Then('the game object plural should be {string}') do |expected|
  assert_equal(expected, game_obj.plural)
end

Then('the game object alert should not raise an error') do
  # If we got here, no error was raised – pass
end

Then('the result should be nil') do
  assert_nil(method_missing_result)
end

Then('the game object should not equal nil') do
  assert_equal(false, game_obj == nil)
end

Then('the game object should equal its own goid') do
  assert(game_obj == game_obj.goid, "Expected game object to equal its own goid")
end

Then('the game object should equal {string}') do |str|
  assert(game_obj == str, "Expected game object to equal '#{str}'")
end

Then('the game object should equal alt name {string}') do |alt|
  assert(game_obj == alt, "Expected game object to equal alt name '#{alt}'")
end

Then('the game object should equal its own class') do
  assert(game_obj == game_obj.class, "Expected game object to equal its own class")
end

Then('the game object should not equal {string}') do |str|
  assert(!(game_obj == str), "Expected game object to NOT equal '#{str}'")
end

Then('the game object long_desc should be {string}') do |expected|
  assert_equal(expected, game_obj.long_desc)
end

Then('the game object long_desc should be the short_desc') do
  assert_equal(game_obj.short_desc, game_obj.long_desc)
end

Then('the game object container should be {string}') do |expected|
  assert_equal(expected, game_obj.container)
end

Then('the game object name should be {string}') do |expected|
  assert_equal(expected, game_obj.name)
end

Then('the game object should be movable') do
  assert(game_obj.can_move?, "Expected game object to be movable")
end

Then('the game object should not be movable') do
  assert(!game_obj.can_move?, "Expected game object to not be movable")
end

Then('the entrance message from {string} should be {string}') do |direction, expected|
  assert_equal(expected, game_obj.entrance_message(direction))
end

Then('the exit message to {string} should be {string}') do |direction, expected|
  assert_equal(expected, game_obj.exit_message(direction))
end
