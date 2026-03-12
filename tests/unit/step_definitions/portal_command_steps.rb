# frozen_string_literal: true
###############################################################################
# Step definitions for PortalCommand action coverage.                         #
###############################################################################
require 'test/unit/assertions'
require 'ostruct'
require 'aethyr/core/actions/commands/portal'
require_relative '../support/test_helpers'

World(Test::Unit::Assertions)

###############################################################################
# World module – scenario-scoped state                                        #
###############################################################################
module PortalWorld
  attr_accessor :portal_player, :portal_object_ref, :portal_setting,
                :portal_value, :portal_target, :portal_find_returns_nil
end
World(PortalWorld)

###############################################################################
# Lightweight doubles                                                         #
###############################################################################

# Info bag that supports dynamic attribute storage and deletion.
class PortalInfoBag < OpenStruct
  def delete(key)
    delete_field(key)
  rescue NameError
    nil
  end
end

# Recording player double that captures output messages.
class PortalPlayer
  attr_accessor :container, :name, :goid
  attr_reader :messages

  def initialize
    @container = "room_goid_1"
    @name      = "TestAdmin"
    @goid      = "player_goid_1"
    @messages  = []
  end

  def output(msg, *_args)
    @messages << msg.to_s
  end
end

# A mock that IS a portal (includes the Portal module so is_a? check passes).
class PortalTargetObject
  include Aethyr::Core::Actions::Portal

  attr_accessor :name, :goid, :info

  def initialize(name = "magic portal")
    @name = name
    @goid = "portal_goid_123"
    @info = PortalInfoBag.new
  end

  def to_s
    @name
  end
end

# A mock that is NOT a portal (does not include the Portal module).
class NonPortalTargetObject
  attr_accessor :name, :goid, :info

  def initialize(name = "a rock")
    @name = name
    @goid = "rock_goid_456"
    @info = PortalInfoBag.new
  end

  def to_s
    @name
  end
end

###############################################################################
# Given steps                                                                 #
###############################################################################
Given('a stubbed PortalCommand environment') do
  @portal_player          = PortalPlayer.new
  @portal_object_ref      = nil
  @portal_setting         = nil
  @portal_value           = nil
  @portal_target          = nil
  @portal_find_returns_nil = false

  # Ensure `log` is available as a no-op.
  unless Object.private_method_defined?(:log)
    Object.class_eval do
      private
      def log(_msg, *_args); end
    end
  end

  # Provide a room object for $manager.get_object(player.container)
  room_obj = OpenStruct.new(name: "Test Room", goid: "room_goid_1")

  # Build a stub manager
  mgr = Object.new

  player_ref    = @portal_player
  find_nil_flag = -> { @portal_find_returns_nil }
  target_ref    = -> { @portal_target }

  mgr.define_singleton_method(:get_object) do |goid|
    if goid == player_ref.container
      room_obj
    else
      nil
    end
  end

  mgr.define_singleton_method(:find) do |name, *_args|
    return nil if find_nil_flag.call
    target_ref.call
  end

  $manager = mgr
end

Given('the portal object reference is {string}') do |ref|
  @portal_object_ref = ref
end

Given('the portal setting is {string}') do |setting|
  @portal_setting = setting
end

Given('the portal value is {string}') do |val|
  @portal_value = val
end

Given('portal find_object will return nil') do
  @portal_find_returns_nil = true
end

Given('a portal target object exists') do
  @portal_target     = PortalTargetObject.new("magic portal")
  @portal_object_ref = @portal_target.goid
end

Given('a non-portal target object exists') do
  @portal_target     = NonPortalTargetObject.new("a rock")
  @portal_object_ref = @portal_target.goid
end

Given('a portal target object exists with exit_message {string}') do |msg|
  @portal_target     = PortalTargetObject.new("magic portal")
  @portal_target.info.exit_message = msg
  @portal_object_ref = @portal_target.goid
end

Given('a portal target object exists with entrance_message {string}') do |msg|
  @portal_target     = PortalTargetObject.new("magic portal")
  @portal_target.info.entrance_message = msg
  @portal_object_ref = @portal_target.goid
end

Given('a portal target object exists with portal_message {string}') do |msg|
  @portal_target     = PortalTargetObject.new("magic portal")
  @portal_target.info.portal_message = msg
  @portal_object_ref = @portal_target.goid
end

###############################################################################
# When steps                                                                  #
###############################################################################
When('the PortalCommand action is invoked') do
  data = {
    object:  @portal_object_ref,
    setting: @portal_setting,
    value:   @portal_value
  }

  cmd = Aethyr::Core::Actions::Portal::PortalCommand.new(@portal_player, **data)

  # Patch find_object on this instance so it returns our controlled target.
  target_ref    = -> { @portal_target }
  find_nil_flag = -> { @portal_find_returns_nil }

  cmd.define_singleton_method(:find_object) do |_name, _event|
    return nil if find_nil_flag.call
    target_ref.call
  end

  cmd.action
end

###############################################################################
# Then steps                                                                  #
###############################################################################
Then('the portal player should see {string}') do |fragment|
  match = @portal_player.messages.any? { |m| m.include?(fragment) }
  assert(match,
    "Expected portal player output containing #{fragment.inspect}, got: #{@portal_player.messages.inspect}")
end
