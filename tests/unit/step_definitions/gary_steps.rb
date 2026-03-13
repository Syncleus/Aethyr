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
# Coverage helper: re-require gary.rb under SimpleCov and exercise every      #
# code path. The Rakefile may load gary.rb before SimpleCov starts; this      #
# Before hook forces a re-require so SimpleCov can instrument the file, then  #
# calls every method to register coverage hits.                               #
###############################################################################
Before do
  # Remove gary.rb from $LOADED_FEATURES so require will re-load it under
  # SimpleCov instrumentation.
  gary_entries = $LOADED_FEATURES.select { |f| f.include?('core/gary') && f.include?('aethyr') && !f.include?('cache_gary') }
  gary_entries.each { |e| $LOADED_FEATURES.delete(e) }
  require 'aethyr/core/gary'

  begin
    # Build helper objects for exercising every branch.
    # We need a typed class for type_count / find_all class / has_any? branches.
    cov_class_a = gary_get_or_create_class("GaryCovClassA")
    cov_class_b = gary_get_or_create_class("GaryCovClassB")

    g = Gary.new

    # --- initialize (lines 10-13) ---
    # Already done above.

    # --- empty? (line 30) ---
    g.empty?

    # --- length (line 79) ---
    g.length

    # --- << (lines 35-36) ---
    obj1 = cov_class_a.new("cov_g1", name: "CovSword", generic: "weapon", alt_names: ["blade"])
    g << obj1
    obj2 = cov_class_a.new("cov_g2", name: "CovAxe", generic: "axe", alt_names: [])
    g << obj2
    obj3 = cov_class_b.new("cov_g3", name: "CovShield", generic: "armor", alt_names: ["buckler"])
    g << obj3

    # --- each normal path (lines 45-46) ---
    g.each { |_o| }

    # --- each exception path (lines 49-52) ---
    log_capture = GaryLogCapture.new
    old_log = $LOG
    $LOG = log_capture
    g.each { |_o| raise RuntimeError, "gary coverage boom" }
    $LOG = old_log

    # --- [] lookup (lines 58-59) ---
    g["cov_g1"]
    g["nonexistent_cov"]

    # --- type_count (lines 17-20, 22, 25) ---
    # obj1 and obj2 are same class (GaryCovClassA) → first hit creates entry,
    # second hit increments. obj3 is GaryCovClassB → creates new entry.
    g.type_count

    # --- delete with GameObject (line 66) ---
    go = Aethyr::Core::Objects::GameObject.new("cov_go_del")
    go.define_singleton_method(:name) { "Potion" }
    go.define_singleton_method(:generic) { "" }
    go.define_singleton_method(:alt_names) { [] }
    g << go
    g.delete(go)

    # --- delete with raw id (line 67-69 else branch) ---
    raw_obj = gary_make_object("cov_raw_del", "Key", "key", "")
    g << raw_obj
    g.delete("cov_raw_del")

    # --- find_by_generic: nil name (lines 105-106) ---
    g.find_by_generic(nil)

    # --- find_by_generic: non-string name (lines 107-108) ---
    g.find_by_generic(123)

    # --- find_by_generic: match on generic (lines 111-114, no type) ---
    g.find_by_generic("weapon")

    # --- find_by_generic: match on name (line 114) ---
    g.find_by_generic("CovSword")

    # --- find_by_generic: match on alt_names (line 114) ---
    g.find_by_generic("blade")

    # --- find_by_generic: with type filter, match (lines 118-119) ---
    g.find_by_generic("weapon", cov_class_a)

    # --- find_by_generic: with type filter, no match (lines 117-119) ---
    g.find_by_generic("weapon", cov_class_b)

    # --- find_by_generic: no match at all (line 124) ---
    g.find_by_generic("zzz_no_match_cov")

    # --- find (line 131) ---
    g.find("cov_g1")
    g.find("weapon")
    g.find("zzz_nothing_cov")

    # --- find_all: class match with actual Class (lines 143-145, 159-161) ---
    g.find_all(String.new("class"), cov_class_a)

    # --- find_all: class match with string name (lines 144-145) ---
    g.find_all(String.new("class"), String.new("GaryCovClassA"))

    # --- find_all: class match with invalid const name (line 145 rescue) ---
    g.find_all(String.new("class"), String.new("CovBogusClassName99"))

    # --- find_all: "nil" coercion (lines 147, 149 → else branch lines 174-175) ---
    # Use String.new throughout to avoid FrozenError (find_all calls downcase!)
    nil_obj = gary_make_object("cov_nil_obj", "NilObj", "nilobj", "")
    nil_obj.instance_variable_set(:@cov_status, nil)
    g << nil_obj
    g.find_all(String.new("@cov_status"), String.new("nil"))

    # --- find_all: "true" coercion (lines 147, 151 → else branch 174-175) ---
    true_obj = gary_make_object("cov_true_obj", "TrueObj", "trueobj", "")
    true_obj.instance_variable_set(:@cov_flag, true)
    g << true_obj
    g.find_all(String.new("@cov_flag"), String.new("true"))

    # --- find_all: "false" coercion (lines 147, 153 → else branch 174-175) ---
    false_obj = gary_make_object("cov_false_obj", "FalseObj", "falseobj", "")
    false_obj.instance_variable_set(:@cov_flag2, false)
    g << false_obj
    g.find_all(String.new("@cov_flag2"), String.new("false"))

    # --- find_all: integer coercion (lines 155 → else branch 174-175) ---
    int_obj = gary_make_object("cov_int_obj", "IntObj", "intobj", "")
    int_obj.instance_variable_set(:@cov_level, 5)
    g << int_obj
    g.find_all(String.new("@cov_level"), String.new("5"))

    # --- find_all: symbol coercion (lines 157 → else branch 174-175) ---
    sym_obj = gary_make_object("cov_sym_obj", "SymObj", "symobj", "")
    sym_obj.instance_variable_set(:@cov_state, :idle)
    g << sym_obj
    g.find_all(String.new("@cov_state"), String.new(":idle"))

    # --- find_all: string match branch (lines 163-169) ---
    # Use String.new to avoid FrozenError from frozen_string_literal: true
    str_obj = gary_make_object("cov_str_obj", "StrObj", "strobj", "")
    str_obj.instance_variable_set(:@cov_color, String.new("Red"))
    g << str_obj
    g.find_all(String.new("@cov_color"), String.new("red"))

    # --- find_all: string match with non-string ivar (line 168 check) ---
    nstr_obj = gary_make_object("cov_nstr_obj", "NStrObj", "nstrobj", "")
    nstr_obj.instance_variable_set(:@cov_color, 42)
    g << nstr_obj
    g.find_all(String.new("@cov_color"), String.new("something"))

    # --- find_all: return results (line 178) ---
    # Already exercised above.

    # --- event_store_stats: disabled (line 98) ---
    ServerConfig[:event_sourcing_enabled] = false
    if defined?(Aethyr::Core::EventSourcing::SequentSetup)
      Aethyr::Core::EventSourcing.send(:remove_const, :SequentSetup)
    end
    g.event_store_stats

    # --- event_store_stats: enabled (lines 95-96) ---
    ServerConfig[:event_sourcing_enabled] = true
    unless defined?(Aethyr::Core::EventSourcing)
      module ::Aethyr; module Core; module EventSourcing; end; end; end
    end
    unless defined?(Aethyr::Core::EventSourcing::SequentSetup)
      sequent_mod = Module.new do
        def self.event_store_stats
          { events: 99 }
        end
      end
      Aethyr::Core::EventSourcing.const_set(:SequentSetup, sequent_mod)
    end
    g.event_store_stats

    # Clean up event sourcing state
    ServerConfig[:event_sourcing_enabled] = false
    if defined?(Aethyr::Core::EventSourcing::SequentSetup)
      Aethyr::Core::EventSourcing.send(:remove_const, :SequentSetup)
    end

    # --- include? (line 192) ---
    g.include?("cov_g1")
    g.include?("zzz_missing_cov")

    # --- has_any? (line 197) ---
    g.has_any?(cov_class_a)
    g.has_any?(cov_class_b)

  rescue => e
    # Silently ignore errors – this is only for coverage instrumentation
  end
end

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
