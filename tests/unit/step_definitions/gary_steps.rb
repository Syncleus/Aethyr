# frozen_string_literal: true
###############################################################################
# Step definitions for Gary (Game ARraY) unit tests                           #
###############################################################################
require 'test/unit/assertions'
require 'ostruct'

World(Test::Unit::Assertions)

###############################################################################
# World module – scenario-scoped state with gary_ prefix                      #
###############################################################################
module GaryWorld
  attr_accessor :gary_instance, :gary_log_messages, :gary_each_count,
                :gary_type_classes, :gary_event_stats_result,
                :gary_game_objects
end
World(GaryWorld)

###############################################################################
# Lightweight stubs – avoid loading the full application                      #
###############################################################################

# Ensure ServerConfig exists
unless defined?(::ServerConfig)
  module ::ServerConfig
    @data = {}
    class << self
      def [](key);       @data[key]; end
      def []=(key, val); @data[key] = val; end
    end
  end
end

# Make sure the `log` helper is available on Object (idempotent).
unless Object.private_method_defined?(:log)
  class Object
    private
    def log(msg, *_args)
      $LOG.add(1, msg.to_s) if defined?($LOG) && $LOG.respond_to?(:add)
    end
  end
end

# Ensure the Aethyr::Core::Objects::GameObject namespace exists for delete checks
unless defined?(Aethyr::Core::Objects::GameObject)
  module ::Aethyr; module Core; module Objects
    class GameObject
      attr_accessor :game_object_id
      def initialize(goid = nil)
        @game_object_id = goid
      end
    end
  end; end; end
end

# Now load the file under test
require 'aethyr/core/gary'

###############################################################################
# Dynamic class registry for typed objects                                    #
###############################################################################
GARY_TEST_CLASSES = {}

def gary_get_or_create_class(class_name)
  return GARY_TEST_CLASSES[class_name] if GARY_TEST_CLASSES.key?(class_name)
  klass = Class.new do
    attr_accessor :game_object_id, :generic, :name, :alt_names
    def initialize(goid, opts = {})
      @game_object_id = goid
      @generic = opts[:generic] || ""
      @name = opts[:name] || ""
      @alt_names = opts[:alt_names] || []
    end
  end
  GARY_TEST_CLASSES[class_name] = klass
  # Register as a top-level constant so Module.const_get can find it
  Object.const_set(class_name.to_sym, klass) unless Object.const_defined?(class_name.to_sym)
  klass
end

###############################################################################
# Helper to build a simple mock game object (uses Struct-like OpenStruct)     #
###############################################################################
def gary_make_object(id, name, generic, alt_names_str)
  alt_names = alt_names_str.to_s.split(",").map(&:strip).reject(&:empty?)
  obj = Object.new
  obj.define_singleton_method(:game_object_id) { id }
  obj.define_singleton_method(:name) { name }
  obj.define_singleton_method(:generic) { generic }
  obj.define_singleton_method(:alt_names) { alt_names }
  obj
end

###############################################################################
# Log capture for exception branch testing                                    #
###############################################################################
class GaryLogCapture
  attr_reader :entries
  def initialize
    @entries = []
  end
  def add(severity, msg = nil, progname = nil, dump_log: false)
    @entries << msg.to_s if msg
  end
  def dump; end
  def clear; end
end

###############################################################################
# Step definitions                                                            #
###############################################################################

Given('a gary test environment is set up') do
  self.gary_log_messages = []
  self.gary_game_objects = {}
  self.gary_type_classes = {}
  # Reset ServerConfig event sourcing flag
  ServerConfig[:event_sourcing_enabled] = false
  # Clean up SequentSetup if defined from a previous scenario
  if defined?(Aethyr::Core::EventSourcing::SequentSetup)
    Aethyr::Core::EventSourcing.send(:remove_const, :SequentSetup)
  end
end

When('I create a new gary instance') do
  self.gary_instance = Gary.new
end

# --- << (add) with simple objects ---

When('I gary add an object with id {string} name {string} generic {string} alt_names {string}') do |id, name, generic, alt_names_str|
  obj = gary_make_object(id, name, generic, alt_names_str)
  self.gary_game_objects[id] = obj
  self.gary_instance << obj
end

# --- add alias ---

When('I gary use add alias with id {string} name {string} generic {string} alt_names {string}') do |id, name, generic, alt_names_str|
  obj = gary_make_object(id, name, generic, alt_names_str)
  self.gary_game_objects[id] = obj
  self.gary_instance.add(obj)
end

# --- typed objects (for type_count, find_all class, has_any?) ---

When('I gary add a typed object with id {string} of gary class {string}') do |id, class_name|
  klass = gary_get_or_create_class(class_name)
  obj = klass.new(id)
  self.gary_game_objects[id] = obj
  self.gary_instance << obj
end

# --- typed findable objects (with generic/name/alt_names + specific class) ---

When('I gary add a typed_findable object with id {string} name {string} generic {string} alt_names {string} of gary class {string}') do |id, name, generic, alt_names_str, class_name|
  klass = gary_get_or_create_class(class_name)
  alt_names = alt_names_str.to_s.split(",").map(&:strip).reject(&:empty?)
  obj = klass.new(id, generic: generic, name: name, alt_names: alt_names)
  self.gary_game_objects[id] = obj
  self.gary_instance << obj
end

# --- game_object (Aethyr::Core::Objects::GameObject) for delete testing ---

When('I gary add a game_object with id {string} name {string}') do |id, name|
  obj = Aethyr::Core::Objects::GameObject.new(id)
  obj.define_singleton_method(:name) { name }
  obj.define_singleton_method(:generic) { "" }
  obj.define_singleton_method(:alt_names) { [] }
  self.gary_game_objects[id] = obj
  self.gary_instance << obj
end

When('I gary delete the game_object with id {string}') do |id|
  obj = self.gary_game_objects[id]
  self.gary_instance.delete(obj)
end

When('I gary delete by raw id {string}') do |id|
  self.gary_instance.delete(id)
end

When('I gary remove by id {string}') do |id|
  self.gary_instance.remove(id)
end

# --- objects with instance variables (for find_all string/nil/true/false/int/sym) ---

When('I gary add an object_with_ivar id {string} ivar {string} value nil') do |id, ivar|
  obj = gary_make_object(id, "ivar_obj_#{id}", "ivar_obj_#{id}", "")
  obj.instance_variable_set(ivar.to_sym, nil)
  self.gary_game_objects[id] = obj
  self.gary_instance << obj
end

When('I gary add an object_with_ivar id {string} ivar {string} value {string}') do |id, ivar, value|
  obj = gary_make_object(id, "ivar_obj_#{id}", "ivar_obj_#{id}", "")
  obj.instance_variable_set(ivar.to_sym, value)
  self.gary_game_objects[id] = obj
  self.gary_instance << obj
end

When('I gary add an object_with_ivar id {string} ivar {string} value true') do |id, ivar|
  obj = gary_make_object(id, "ivar_obj_#{id}", "ivar_obj_#{id}", "")
  obj.instance_variable_set(ivar.to_sym, true)
  self.gary_game_objects[id] = obj
  self.gary_instance << obj
end

When('I gary add an object_with_ivar id {string} ivar {string} value false') do |id, ivar|
  obj = gary_make_object(id, "ivar_obj_#{id}", "ivar_obj_#{id}", "")
  obj.instance_variable_set(ivar.to_sym, false)
  self.gary_game_objects[id] = obj
  self.gary_instance << obj
end

When('I gary add an object_with_ivar id {string} ivar {string} value_int {int}') do |id, ivar, value|
  obj = gary_make_object(id, "ivar_obj_#{id}", "ivar_obj_#{id}", "")
  obj.instance_variable_set(ivar.to_sym, value)
  self.gary_game_objects[id] = obj
  self.gary_instance << obj
end

When('I gary add an object_with_ivar id {string} ivar {string} value_sym {string}') do |id, ivar, value|
  obj = gary_make_object(id, "ivar_obj_#{id}", "ivar_obj_#{id}", "")
  obj.instance_variable_set(ivar.to_sym, value.to_sym)
  self.gary_game_objects[id] = obj
  self.gary_instance << obj
end

# --- each with exception ---

When('I iterate gary each with a block that raises an exception') do
  # Install log capture
  log_capture = GaryLogCapture.new
  $LOG = log_capture
  self.gary_log_messages = log_capture.entries

  self.gary_instance.each do |obj|
    raise RuntimeError, "gary test explosion"
  end
end

# --- event_store_stats ---

When('gary event sourcing is enabled') do
  ServerConfig[:event_sourcing_enabled] = true
  # Define the SequentSetup stub module with event_store_stats
  unless defined?(Aethyr::Core::EventSourcing)
    module ::Aethyr; module Core; module EventSourcing; end; end; end
  end
  # Define SequentSetup as a module with a class method
  sequent_mod = Module.new do
    def self.event_store_stats
      { events: 42, aggregates: 7 }
    end
  end
  Aethyr::Core::EventSourcing.const_set(:SequentSetup, sequent_mod)
end

###############################################################################
# Then steps                                                                  #
###############################################################################

Then('the gary should be empty') do
  assert self.gary_instance.empty?, "Expected Gary to be empty"
end

Then('the gary should not be empty') do
  assert !self.gary_instance.empty?, "Expected Gary to not be empty"
end

Then('the gary length should be {int}') do |expected|
  assert_equal expected, self.gary_instance.length
end

Then('the gary count should be {int}') do |expected|
  assert_equal expected, self.gary_instance.count
end

Then('gary lookup by id {string} should return the object named {string}') do |id, expected_name|
  result = self.gary_instance[id]
  assert_not_nil result, "Expected to find object with id '#{id}'"
  assert_equal expected_name, result.name
end

Then('gary lookup by id {string} should return nil') do |id|
  result = self.gary_instance[id]
  assert_nil result, "Expected nil for id '#{id}' but got #{result.inspect}"
end

Then('gary each should yield {int} objects') do |expected|
  count = 0
  self.gary_instance.each { |_| count += 1 }
  assert_equal expected, count
end

Then('the gary log should have captured the exception message') do
  messages = self.gary_log_messages
  assert messages.any? { |m| m.include?("Exception occured") || m.include?("gary test explosion") },
    "Expected log to contain exception info, got: #{messages.inspect}"
end

Then('gary type_count should show {int} for gary class {string}') do |expected, class_name|
  tc = self.gary_instance.type_count
  klass = GARY_TEST_CLASSES[class_name]
  assert_not_nil klass, "Test class #{class_name} not found"
  assert_equal expected, tc[klass], "Expected #{expected} for #{class_name}, got #{tc[klass].inspect}. Full: #{tc.inspect}"
end

# --- find_by_generic ---

Then('gary find_by_generic with nil name should return nil') do
  result = self.gary_instance.find_by_generic(nil)
  assert_nil result
end

Then('gary find_by_generic with integer name {int} should return the object named {string}') do |int_name, expected_name|
  result = self.gary_instance.find_by_generic(int_name)
  assert_not_nil result, "Expected find_by_generic(#{int_name}) to return an object"
  assert_equal expected_name, result.name
end

Then('gary find_by_generic {string} should return the object named {string}') do |search, expected_name|
  result = self.gary_instance.find_by_generic(search)
  assert_not_nil result, "Expected find_by_generic('#{search}') to return an object"
  assert_equal expected_name, result.name
end

Then('gary find_by_generic {string} should return nil') do |search|
  result = self.gary_instance.find_by_generic(search)
  assert_nil result, "Expected find_by_generic('#{search}') to return nil, got #{result.inspect}"
end

Then('gary find_by_generic {string} with type {string} should return the object named {string}') do |search, type_name, expected_name|
  klass = GARY_TEST_CLASSES[type_name]
  assert_not_nil klass, "Test class #{type_name} not registered"
  result = self.gary_instance.find_by_generic(search, klass)
  assert_not_nil result, "Expected find_by_generic('#{search}', #{type_name}) to return an object"
  assert_equal expected_name, result.name
end

Then('gary find_by_generic {string} with type {string} should return nil') do |search, type_name|
  # For non-matching type, create a distinct class that won't match
  klass = gary_get_or_create_class(type_name)
  result = self.gary_instance.find_by_generic(search, klass)
  assert_nil result, "Expected nil for type #{type_name}, got #{result.inspect}"
end

# --- find ---

Then('gary find {string} should return the object named {string}') do |search, expected_name|
  result = self.gary_instance.find(search)
  assert_not_nil result, "Expected find('#{search}') to return an object"
  assert_equal expected_name, result.name
end

Then('gary find {string} should return nil') do |search|
  result = self.gary_instance.find(search)
  assert_nil result, "Expected find('#{search}') to return nil"
end

# --- find_all ---

Then('gary find_all by class {string} should return {int} result(s)') do |class_name, expected|
  klass = GARY_TEST_CLASSES[class_name]
  assert_not_nil klass, "Test class #{class_name} not registered"
  results = self.gary_instance.find_all("class", klass)
  assert_equal expected, results.length, "Expected #{expected} results for class #{class_name}, got #{results.length}"
end

Then('gary find_all by class string {string} should return {int} result(s)') do |class_name, expected|
  results = self.gary_instance.find_all("class", class_name)
  assert_equal expected, results.length, "Expected #{expected} results for class string '#{class_name}', got #{results.length}"
end

Then('gary find_all with attrib {string} match {string} should return {int} result(s)') do |attrib, match, expected|
  results = self.gary_instance.find_all(attrib, match)
  assert_equal expected, results.length, "Expected #{expected} results for attrib=#{attrib} match=#{match}, got #{results.length}"
end

# --- find_by_id ---

Then('gary find_by_id {string} should return the object named {string}') do |id, expected_name|
  result = self.gary_instance.find_by_id(id)
  assert_not_nil result, "Expected find_by_id('#{id}') to return an object"
  assert_equal expected_name, result.name
end

Then('gary find_by_id {string} should return nil') do |id|
  result = self.gary_instance.find_by_id(id)
  assert_nil result
end

# --- event_store_stats ---

Then('gary event_store_stats should return an empty hash') do
  result = self.gary_instance.event_store_stats
  assert_equal({}, result)
end

Then('gary event_store_stats should return the delegated stats') do
  result = self.gary_instance.event_store_stats
  assert_equal({ events: 42, aggregates: 7 }, result)
end

# --- include? ---

Then('gary include? {string} should be true') do |search|
  assert self.gary_instance.include?(search), "Expected include?('#{search}') to be true"
end

Then('gary include? {string} should be false') do |search|
  assert !self.gary_instance.include?(search), "Expected include?('#{search}') to be false"
end

# --- has_any? ---

Then('gary has_any? {string} should be true') do |class_name|
  klass = GARY_TEST_CLASSES[class_name]
  assert_not_nil klass, "Test class #{class_name} not registered"
  assert self.gary_instance.has_any?(klass), "Expected has_any?(#{class_name}) to be true"
end

Then('gary has_any? {string} should be false') do |class_name|
  klass = gary_get_or_create_class(class_name)
  assert !self.gary_instance.has_any?(klass), "Expected has_any?(#{class_name}) to be false"
end
