# frozen_string_literal: true
###############################################################################
# Step definitions for AconfigCommand action coverage.                        #
###############################################################################
require 'test/unit/assertions'
require 'aethyr/core/actions/commands/aconfig'
require 'aethyr/core/util/config'
require_relative '../support/test_helpers'

World(Test::Unit::Assertions)

###############################################################################
# World module – scenario-scoped state                                        #
###############################################################################
module AconfigWorld
  attr_accessor :acfg_player, :acfg_setting, :acfg_value,
                :acfg_reload_called, :acfg_has_setting_result,
                :acfg_assigned_settings,
                :acfg_orig_reload, :acfg_orig_has_setting,
                :acfg_orig_bracket_eq, :acfg_orig_to_s
end
World(AconfigWorld)

###############################################################################
# Lightweight doubles                                                         #
###############################################################################

# Recording player double that captures output messages.
class AcfgMockPlayer
  attr_accessor :container, :name
  attr_reader :messages

  def initialize
    @container = "acfg_room_goid_1"
    @name      = "TestAdmin"
    @messages  = []
  end

  def output(msg, *_args)
    @messages << msg.to_s
  end
end

###############################################################################
# Given steps                                                                 #
###############################################################################
Given('a stubbed AconfigCommand environment') do
  @acfg_player             = AcfgMockPlayer.new
  @acfg_setting            = nil
  @acfg_value              = nil
  @acfg_reload_called      = false
  @acfg_has_setting_result = false
  @acfg_assigned_settings  = {}

  # Ensure `log` is available as a no-op
  unless Object.private_method_defined?(:log)
    Object.class_eval do
      private
      def log(_msg, *_args); end
    end
  end

  # Build a stub manager
  room_obj    = Object.new
  room_obj.define_singleton_method(:name) { "Test Room" }
  player_ref  = @acfg_player

  mgr = Object.new
  mgr.define_singleton_method(:get_object) do |goid|
    room_obj if goid == player_ref.container
  end
  $manager = mgr

  # Save original ServerConfig methods so we can restore them after the scenario.
  @acfg_orig_reload      = ServerConfig.method(:reload) if ServerConfig.respond_to?(:reload)
  @acfg_orig_has_setting = ServerConfig.method(:has_setting?) if ServerConfig.respond_to?(:has_setting?)
  @acfg_orig_bracket_eq  = ServerConfig.method(:[]=) if ServerConfig.respond_to?(:[]=)
  @acfg_orig_to_s        = ServerConfig.method(:to_s)

  # Stub ServerConfig singleton methods per-scenario.
  acfg_world = self

  ServerConfig.define_singleton_method(:reload) do
    acfg_world.acfg_reload_called = true
  end

  ServerConfig.define_singleton_method(:has_setting?) do |setting|
    acfg_world.acfg_has_setting_result
  end

  ServerConfig.define_singleton_method(:[]=) do |key, value|
    acfg_world.acfg_assigned_settings[key] = value
  end

  ServerConfig.define_singleton_method(:to_s) do
    "stubbed_config_output"
  end
end

Given('the acfg setting is not provided') do
  @acfg_setting = nil
end

Given('the acfg setting is {string}') do |setting|
  @acfg_setting = setting
end

Given('the acfg value is {string}') do |value|
  @acfg_value = value
end

Given('the acfg ServerConfig does not have that setting') do
  @acfg_has_setting_result = false
end

Given('the acfg ServerConfig has that setting') do
  @acfg_has_setting_result = true
end

###############################################################################
# When steps                                                                  #
###############################################################################
When('the AconfigCommand action is invoked') do
  data = {}
  data[:setting] = @acfg_setting unless @acfg_setting.nil?
  data[:value]   = @acfg_value   unless @acfg_value.nil?

  cmd = Aethyr::Core::Actions::Aconfig::AconfigCommand.new(@acfg_player, **data)
  cmd.action
end

###############################################################################
# Then steps                                                                  #
###############################################################################
Then('the acfg player should see {string}') do |fragment|
  match = @acfg_player.messages.any? { |m| m.include?(fragment) }
  assert(match,
    "Expected acfg player output containing #{fragment.inspect}, got: #{@acfg_player.messages.inspect}")
end

Then('the acfg ServerConfig reload should have been called') do
  assert(@acfg_reload_called,
    "Expected ServerConfig.reload to have been called, but it was not.")
end

Then('the acfg ServerConfig should have received setting {string} with integer {int}') do |key, expected|
  actual = @acfg_assigned_settings[key.to_sym]
  assert_equal(expected, actual,
    "Expected ServerConfig[:#{key}] to be set to #{expected} (Integer), got: #{actual.inspect}")
end

Then('the acfg ServerConfig should have received setting {string} with string {string}') do |key, expected|
  actual = @acfg_assigned_settings[key.to_sym]
  assert_equal(expected, actual,
    "Expected ServerConfig[:#{key}] to be set to #{expected.inspect} (String), got: #{actual.inspect}")
end

###############################################################################
# After hook – restore original ServerConfig methods                          #
###############################################################################
After do
  if @acfg_orig_reload
    ServerConfig.define_singleton_method(:reload, @acfg_orig_reload)
    @acfg_orig_reload = nil
  end
  if @acfg_orig_has_setting
    ServerConfig.define_singleton_method(:has_setting?, @acfg_orig_has_setting)
    @acfg_orig_has_setting = nil
  end
  if @acfg_orig_bracket_eq
    ServerConfig.define_singleton_method(:[]=, @acfg_orig_bracket_eq)
    @acfg_orig_bracket_eq = nil
  end
  if @acfg_orig_to_s
    ServerConfig.define_singleton_method(:to_s, @acfg_orig_to_s)
    @acfg_orig_to_s = nil
  end
end
