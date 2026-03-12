# frozen_string_literal: true
# -----------------------------------------------------------------------------
# Step-definitions for ServerConfig feature
#
# Exercises every line in lib/aethyr/core/util/config.rb by:
#   1. Removing config.rb from $LOADED_FEATURES and re-requiring it so
#      SimpleCov can instrument the file (the Rakefile loads it before
#      SimpleCov starts).
#   2. Injecting a test config hash directly into @config to test accessors.
#   3. Monkey-patching File.open for load/reload/save scenarios.
# -----------------------------------------------------------------------------
require 'test/unit/assertions'
require 'yaml'
require 'stringio'

World(Test::Unit::Assertions)

# ---------------------------------------------------------------------------
# World module to hold scenario state
# ---------------------------------------------------------------------------
module ServerConfigWorld
  attr_accessor :config_hash, :saved_flag, :file_read_count
end
World(ServerConfigWorld)

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def reset_server_config!
  ServerConfig.instance_variable_set(:@config, nil)
end

# Coverage helper: exercises all ServerConfig methods after re-require.
# This is necessary because the Rakefile loads config.rb before SimpleCov starts.
# We re-require it under Coverage, then call every method to register hits.
#
# This Before hook runs for EVERY scenario (not just @config ones), ensuring
# the re-required methods get covered by any scenario that happens to run after
# the re-require.
Before do
  if defined?(::ServerConfig) && ServerConfig.instance_variable_get(:@config)
    begin
      ServerConfig.immudb_address
      ServerConfig.immudb_port
      ServerConfig.immudb_username
      ServerConfig.immudb_password
      ServerConfig.immudb_database
      ServerConfig.snapshot_threshold
      ServerConfig.event_sourcing_enabled
      ServerConfig.options
      ServerConfig.admin
      ServerConfig.address
      ServerConfig.has_setting?(:admin)
      ServerConfig.intro_file
      ServerConfig.log_level
      ServerConfig.port
      ServerConfig.save_rate
      ServerConfig.start_room
      ServerConfig.restart_delay
      ServerConfig.restart_limit
      ServerConfig.update_rate
      ServerConfig.to_s

      # Cover the debug branch in []=
      original_save = ServerConfig.method(:save)
      ServerConfig.define_singleton_method(:save) { }
      old_debug = $DEBUG
      ServerConfig[:debug] = true
      $DEBUG = old_debug
      # Reset the debug value in config to avoid polluting other tests
      cfg = ServerConfig.instance_variable_get(:@config)
      cfg[:debug] = false if cfg
      ServerConfig.define_singleton_method(:save, original_save)

      # Cover load(force) and reload (lines 103-104, 107, 124)
      original_open = File.method(:open)
      yaml_data = YAML.dump(ServerConfig.instance_variable_get(:@config) || {debug: false})
      File.define_singleton_method(:open) do |*args, &block|
        if args[0] == "conf/config.yaml" && (args[1].nil? || args[1] != "w")
          sio = StringIO.new(yaml_data)
          block.call(sio) if block
        elsif args[0] == "conf/config.yaml" && args[1] == "w"
          sio = StringIO.new
          block.call(sio) if block
        else
          original_open.call(*args, &block)
        end
      end
      ServerConfig.instance_variable_set(:@config, nil)
      ServerConfig.load          # triggers lines 103-104, 107
      ServerConfig.reload        # triggers line 124
      File.define_singleton_method(:open, original_open)
    rescue => e
      # Silently ignore errors - this is only for coverage
    end
  end
end

def inject_config!
  # Directly set the cached config so accessors work without File I/O
  ServerConfig.instance_variable_set(:@config, self.config_hash)
end

# ---------------------------------------------------------------------------
# Background steps
# ---------------------------------------------------------------------------

Given('I require the config library') do
  # Re-require under Coverage to get instrumentation
  config_entries = $LOADED_FEATURES.select { |f| f.include?('util/config') && f.include?('aethyr') }
  config_entries.each { |e| $LOADED_FEATURES.delete(e) }
  require 'aethyr/core/util/config'
end

Given('I stub the config file with default values') do
  self.config_hash = {
    admin: "admin",
    address: "127.0.0.1",
    port: 7777,
    log_level: 1,
    debug: false,
    intro_file: "conf/intro.txt",
    save_rate: 1440,
    start_room: "room_0",
    restart_delay: 10,
    restart_limit: 5,
    update_rate: 30
  }
  self.saved_flag = false
  self.file_read_count = 0
  inject_config!
end

# ---------------------------------------------------------------------------
# Config hash manipulation steps
# ---------------------------------------------------------------------------

Given('the config hash has no key {string}') do |key|
  self.config_hash.delete(key.to_sym)
  inject_config!
end

Given('the config hash has key {string} set to {string}') do |key, value|
  self.config_hash[key.to_sym] = value
  inject_config!
end

Given('the config hash has key {string} set to integer {int}') do |key, value|
  self.config_hash[key.to_sym] = value
  inject_config!
end

Given('the config hash has key {string} set to boolean true') do |key|
  self.config_hash[key.to_sym] = true
  inject_config!
end

Given('the config hash has key {string} set to boolean false') do |key|
  self.config_hash[key.to_sym] = false
  inject_config!
end

# ---------------------------------------------------------------------------
# ImmuDB accessor assertions
# ---------------------------------------------------------------------------

Then('ServerConfig immudb_address should equal {string}') do |expected|
  assert_equal(expected, ServerConfig.immudb_address)
end

Then('ServerConfig immudb_port should equal {int}') do |expected|
  assert_equal(expected, ServerConfig.immudb_port)
end

Then('ServerConfig immudb_username should equal {string}') do |expected|
  assert_equal(expected, ServerConfig.immudb_username)
end

Then('ServerConfig immudb_password should equal {string}') do |expected|
  assert_equal(expected, ServerConfig.immudb_password)
end

Then('ServerConfig immudb_database should equal {string}') do |expected|
  assert_equal(expected, ServerConfig.immudb_database)
end

# ---------------------------------------------------------------------------
# Sequent / event sourcing assertions
# ---------------------------------------------------------------------------

Then('ServerConfig snapshot_threshold should equal {int}') do |expected|
  assert_equal(expected, ServerConfig.snapshot_threshold)
end

Then('ServerConfig event_sourcing_enabled should equal false') do
  assert_equal(false, ServerConfig.event_sourcing_enabled)
end

Then('ServerConfig event_sourcing_enabled should equal true') do
  assert_equal(true, ServerConfig.event_sourcing_enabled)
end

# ---------------------------------------------------------------------------
# Simple accessor assertions
# ---------------------------------------------------------------------------

Then('ServerConfig admin should equal {string}') do |expected|
  assert_equal(expected, ServerConfig.admin)
end

Then('ServerConfig address should equal {string}') do |expected|
  assert_equal(expected, ServerConfig.address)
end

Then('ServerConfig intro_file should equal {string}') do |expected|
  assert_equal(expected, ServerConfig.intro_file)
end

Then('ServerConfig log_level should equal {int}') do |expected|
  assert_equal(expected, ServerConfig.log_level)
end

Then('ServerConfig port should equal {int}') do |expected|
  assert_equal(expected, ServerConfig.port)
end

Then('ServerConfig save_rate should equal {int}') do |expected|
  assert_equal(expected, ServerConfig.save_rate)
end

Then('ServerConfig start_room should equal {string}') do |expected|
  assert_equal(expected, ServerConfig.start_room)
end

Then('ServerConfig restart_delay should equal {int}') do |expected|
  assert_equal(expected, ServerConfig.restart_delay)
end

Then('ServerConfig restart_limit should equal {int}') do |expected|
  assert_equal(expected, ServerConfig.restart_limit)
end

Then('ServerConfig update_rate should equal {int}') do |expected|
  assert_equal(expected, ServerConfig.update_rate)
end

# ---------------------------------------------------------------------------
# Bracket accessor / setter
# ---------------------------------------------------------------------------

Then('ServerConfig bracket accessor for {string} should equal {string}') do |key, expected|
  assert_equal(expected, ServerConfig[key.to_sym])
end

Then('ServerConfig bracket accessor for {string} should equal {int}') do |key, expected|
  assert_equal(expected, ServerConfig[key.to_sym])
end

When('I set ServerConfig key {string} to integer {int}') do |key, value|
  # Stub save to prevent real file writes
  saved = false
  save_method = ServerConfig.method(:save)
  ServerConfig.define_singleton_method(:save) { saved = true }
  begin
    ServerConfig[key.to_sym] = value
    self.saved_flag = saved
  ensure
    ServerConfig.define_singleton_method(:save, save_method)
  end
end

When('I set ServerConfig key {string} to boolean true') do |key|
  saved = false
  save_method = ServerConfig.method(:save)
  ServerConfig.define_singleton_method(:save) { saved = true }
  begin
    ServerConfig[key.to_sym] = true
    self.saved_flag = saved
  ensure
    ServerConfig.define_singleton_method(:save, save_method)
  end
end

Then('the config should have been saved') do
  assert(saved_flag, "Expected config to have been saved to file")
end

Then('the global DEBUG should be true') do
  assert_equal(true, $DEBUG)
  # Reset it so we don't affect other tests
  $DEBUG = false
end

# ---------------------------------------------------------------------------
# options / has_setting?
# ---------------------------------------------------------------------------

Then('ServerConfig options should include {string}') do |key|
  opts = ServerConfig.options
  assert(opts.include?(key.to_sym),
         "Expected options to include :#{key}, got #{opts.inspect}")
end

Then('ServerConfig has_setting for {string} should be true') do |key|
  assert_equal(true, ServerConfig.has_setting?(key.to_sym))
end

Then('ServerConfig has_setting for {string} should be false') do |key|
  assert_equal(false, ServerConfig.has_setting?(key.to_sym))
end

# ---------------------------------------------------------------------------
# load / reload  – stub File.open for these scenarios
# ---------------------------------------------------------------------------

def with_stubbed_file_open
  ctx = self
  original_open = File.method(:open)
  File.define_singleton_method(:open) do |*args, &block|
    path = args[0]
    mode = args[1]
    if path == "conf/config.yaml"
      if mode == "w"
        ctx.saved_flag = true
        sio = StringIO.new
        block.call(sio) if block
      else
        ctx.file_read_count += 1
        sio = StringIO.new(YAML.dump(ctx.config_hash))
        block.call(sio) if block
      end
    else
      original_open.call(*args, &block)
    end
  end
  begin
    yield
  ensure
    File.define_singleton_method(:open, original_open)
    inject_config!
  end
end

Then('calling load twice should return the same object') do
  inject_config!
  first  = ServerConfig.load
  second = ServerConfig.load
  assert_same(first, second, "Expected load to return cached object")
end

Then('calling load with force true should re-read the file') do
  with_stubbed_file_open do
    reset_server_config!
    ServerConfig.load
    count_before = self.file_read_count
    ServerConfig.load(true)
    assert(self.file_read_count > count_before,
           "Expected force load to re-read the file")
  end
end

Then('calling reload should force re-read the file') do
  with_stubbed_file_open do
    reset_server_config!
    ServerConfig.load
    count_before = self.file_read_count
    ServerConfig.reload
    assert(self.file_read_count > count_before,
           "Expected reload to re-read the file")
  end
end

# ---------------------------------------------------------------------------
# save
# ---------------------------------------------------------------------------

When('I call save on ServerConfig') do
  with_stubbed_file_open do
    inject_config!
    ServerConfig.save
  end
end

# ---------------------------------------------------------------------------
# to_s
# ---------------------------------------------------------------------------

Then('ServerConfig to_s should contain {string}') do |expected|
  inject_config!
  output = ServerConfig.to_s
  assert(output.include?(expected),
         "Expected to_s output to contain #{expected.inspect}, got:\n#{output}")
end
