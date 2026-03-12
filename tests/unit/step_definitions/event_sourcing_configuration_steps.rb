# frozen_string_literal: true

###############################################################################
# Step definitions for Aethyr::EventSourcing::Configuration                   #
###############################################################################
require 'test/unit/assertions'
require 'singleton'
require 'aethyr/event_sourcing/configuration'

World(Test::Unit::Assertions)

# Helper to build a Configuration instance while controlling ENV vars.
# We call send(:new) to bypass Singleton's private constructor restriction
# so each scenario gets a fresh instance.
module ConfigurationWorld
  attr_accessor :config, :config_error

  # Creates a fresh Configuration bypassing singleton memoisation.
  # Accepts an optional hash of ENV overrides.
  def build_configuration(env_overrides = {})
    saved = {}
    env_keys = %w[
      IMMUDB_HOST IMMUDB_PORT IMMUDB_USER IMMUDB_PASS
      SNAPSHOT_FREQUENCY RETRY_ATTEMPTS RETRY_BASE_DELAY RETRY_MAX_DELAY
    ]

    # Save current ENV and apply overrides / deletions
    env_keys.each do |k|
      saved[k] = ENV[k]
      if env_overrides.key?(k)
        if env_overrides[k].nil?
          ENV.delete(k)
        else
          ENV[k] = env_overrides[k].to_s
        end
      else
        ENV.delete(k)
      end
    end

    begin
      self.config_error = nil
      obj = Aethyr::EventSourcing::Configuration.send(:new)
      self.config = obj
    rescue ArgumentError => e
      self.config_error = e
      self.config = nil
    ensure
      # Restore original ENV
      saved.each do |k, v|
        if v.nil?
          ENV.delete(k)
        else
          ENV[k] = v
        end
      end
    end
  end
end
World(ConfigurationWorld)

###############################################################################
# Given steps                                                                  #
###############################################################################

Given('I create a fresh Configuration instance with default env') do
  build_configuration
end

Given('I create a fresh Configuration instance with custom env') do
  build_configuration(
    'IMMUDB_HOST'        => 'custom-host',
    'IMMUDB_PORT'        => '5555',
    'IMMUDB_USER'        => 'admin',
    'IMMUDB_PASS'        => 'secret',
    'SNAPSHOT_FREQUENCY'  => '1000',
    'RETRY_ATTEMPTS'      => '10',
    'RETRY_BASE_DELAY'    => '0.5',
    'RETRY_MAX_DELAY'     => '30.0'
  )
end

Given('I obtain the Configuration singleton instance') do
  # Reset the cached singleton so we exercise self.instance fully
  Aethyr::EventSourcing::Configuration.instance_variable_set(:@instance, nil)
  self.config = Aethyr::EventSourcing::Configuration.instance
end

###############################################################################
# When steps                                                                   #
###############################################################################

When('I access an unknown configuration key :bogus') do
  begin
    self.config_error = nil
    config[:bogus]
  rescue ArgumentError => e
    self.config_error = e
  end
end

When('I create a Configuration with empty immudb_host') do
  build_configuration('IMMUDB_HOST' => '   ')
end

When('I create a Configuration with nil immudb_host') do
  # ENV cannot hold nil; simulate by setting to empty string
  build_configuration('IMMUDB_HOST' => '')
end

When('I create a Configuration with immudb_port {int}') do |port|
  build_configuration('IMMUDB_PORT' => port.to_s)
end

When('I create a Configuration with empty immudb_user') do
  build_configuration('IMMUDB_USER' => '')
end

When('I create a Configuration with empty immudb_pass') do
  build_configuration('IMMUDB_PASS' => '')
end

When('I create a Configuration with snapshot_frequency {int}') do |val|
  build_configuration('SNAPSHOT_FREQUENCY' => val.to_s)
end

When('I create a Configuration with retry_attempts {int}') do |val|
  build_configuration('RETRY_ATTEMPTS' => val.to_s)
end

When('I create a Configuration with retry_base_delay {int}') do |val|
  build_configuration('RETRY_BASE_DELAY' => val.to_s)
end

When('I create a Configuration with retry_max_delay not greater than base delay') do
  build_configuration(
    'RETRY_BASE_DELAY' => '5.0',
    'RETRY_MAX_DELAY'  => '5.0'
  )
end

###############################################################################
# Then steps                                                                   #
###############################################################################

Then('the configuration immudb_host should be {string}') do |expected|
  assert_equal(expected, config.immudb_host)
end

Then('the configuration immudb_port should be {int}') do |expected|
  assert_equal(expected, config.immudb_port)
end

Then('the configuration immudb_user should be {string}') do |expected|
  assert_equal(expected, config.immudb_user)
end

Then('the configuration immudb_pass should be {string}') do |expected|
  assert_equal(expected, config.immudb_pass)
end

Then('the configuration snapshot_frequency should be {int}') do |expected|
  assert_equal(expected, config.snapshot_frequency)
end

Then('the configuration retry_attempts should be {int}') do |expected|
  assert_equal(expected, config.retry_attempts)
end

Then('the configuration retry_base_delay should be {float}') do |expected|
  assert_in_delta(expected, config.retry_base_delay, 0.001)
end

Then('the configuration retry_max_delay should be {float}') do |expected|
  assert_in_delta(expected, config.retry_max_delay, 0.001)
end

Then('the singleton instance should be a Configuration') do
  assert_instance_of(Aethyr::EventSourcing::Configuration, config)
end

Then('obtaining the instance again should return the same object') do
  second = Aethyr::EventSourcing::Configuration.instance
  assert_same(config, second,
              'Expected Configuration.instance to return the same object')
end

Then('accessing config key :immudb_host should return {string}') do |expected|
  assert_equal(expected, config[:immudb_host])
end

Then('accessing config key :immudb_port should return {int}') do |expected|
  assert_equal(expected, config[:immudb_port])
end

Then('accessing config key :immudb_user should return {string}') do |expected|
  assert_equal(expected, config[:immudb_user])
end

Then('accessing config key :immudb_pass should return {string}') do |expected|
  assert_equal(expected, config[:immudb_pass])
end

Then('accessing config key :snapshot_frequency should return {int}') do |expected|
  assert_equal(expected, config[:snapshot_frequency])
end

Then('accessing config key :retry_attempts should return {int}') do |expected|
  assert_equal(expected, config[:retry_attempts])
end

Then('accessing config key :retry_base_delay should return {float}') do |expected|
  assert_in_delta(expected, config[:retry_base_delay], 0.001)
end

Then('accessing config key :retry_max_delay should return {float}') do |expected|
  assert_in_delta(expected, config[:retry_max_delay], 0.001)
end

Then('a configuration ArgumentError should be raised with message {string}') do |expected_msg|
  assert_not_nil(config_error, "Expected an ArgumentError but none was raised")
  assert_equal(expected_msg, config_error.message)
end

Then('a configuration ArgumentError should have been raised with message {string}') do |expected_msg|
  assert_not_nil(config_error, "Expected an ArgumentError but none was raised")
  assert_equal(expected_msg, config_error.message)
end

Then('the immudb_address should be {string}') do |expected|
  assert_equal(expected, config.immudb_address)
end

Then('the connection_params should include address {string}') do |expected|
  assert_equal(expected, config.connection_params[:address])
end

Then('the connection_params should include username {string}') do |expected|
  assert_equal(expected, config.connection_params[:username])
end

Then('the connection_params should include password {string}') do |expected|
  assert_equal(expected, config.connection_params[:password])
end

Then('the to_s output should contain {string}') do |expected|
  output = config.to_s
  assert(output.include?(expected),
         "Expected to_s output to contain #{expected.inspect}, got:\n#{output}")
end

Then('the to_s output should contain masked password') do
  output = config.to_s
  masked = '*' * config.immudb_pass.length
  assert(output.include?("ImmuDB Password: #{masked}"),
         "Expected to_s to contain masked password '#{masked}', got:\n#{output}")
end
