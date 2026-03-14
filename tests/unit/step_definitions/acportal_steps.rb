# frozen_string_literal: true
###############################################################################
# Step definitions for AcportalCommand action coverage.                       #
###############################################################################
require 'test/unit/assertions'
require 'ostruct'
require 'aethyr/core/actions/commands/acportal'
require_relative '../support/test_helpers'

World(Test::Unit::Assertions)

###############################################################################
# World module – scenario-scoped state                                        #
###############################################################################
module AcportalWorld
  attr_accessor :acportal_player, :acportal_portal_action,
                :acportal_admin_calls, :acportal_created_object
end
World(AcportalWorld)

###############################################################################
# Lightweight doubles                                                         #
###############################################################################

# Recording player double that captures output messages.
class AcportalPlayer
  attr_accessor :container, :name, :goid
  attr_reader :messages

  def initialize
    @container = "acportal_room_goid_1"
    @name      = "AcportalTestAdmin"
    @goid      = "acportal_player_goid_1"
    @messages  = []
  end

  def output(msg, *_args)
    @messages << msg.to_s
  end
end

# Info double that records portal_action assignment.
class AcportalInfoBag
  attr_reader :portal_action_was_set
  attr_accessor :portal_action

  def initialize
    @portal_action     = nil
    @portal_action_was_set = false
  end

  def portal_action=(value)
    @portal_action     = value
    @portal_action_was_set = true
  end
end

# Minimal created-object double with an info bag.
class AcportalCreatedObject
  attr_accessor :name, :info

  def initialize
    @name = "a test portal"
    @info = AcportalInfoBag.new
  end
end

# Minimal room double.
class AcportalRoom
  def name;  "Acportal Test Room"; end
  def goid;  "acportal_room_goid_1"; end
end

###############################################################################
# Given steps                                                                 #
###############################################################################
Given('a stubbed AcportalCommand environment') do
  @acportal_player        = AcportalPlayer.new
  @acportal_portal_action = nil
  @acportal_admin_calls   = []
  @acportal_created_object = AcportalCreatedObject.new

  room_ref       = AcportalRoom.new
  player_ref     = @acportal_player
  created_obj    = @acportal_created_object
  admin_calls    = @acportal_admin_calls

  # Stub $manager
  mgr = Object.new
  mgr.define_singleton_method(:get_object) do |goid|
    if goid == player_ref.container
      room_ref
    end
  end
  $manager = mgr

  # Ensure `log` is available as a no-op.
  unless Object.private_method_defined?(:log)
    Object.class_eval do
      private
      def log(_msg, *_args); end
    end
  end

  # Stub Admin.acreate to return our mock object and record calls.
  unless defined?(::Admin)
    Object.const_set(:Admin, Module.new)
  end

  ::Admin.define_singleton_method(:acreate) do |event, _player, _room|
    admin_calls << event
    created_obj
  end
end

Given('no acportal portal_action is provided') do
  @acportal_portal_action = nil
end

Given('the acportal portal_action is {string}') do |value|
  @acportal_portal_action = value
end

###############################################################################
# When steps                                                                  #
###############################################################################
When('the AcportalCommand action is invoked') do
  data = {}
  data[:portal_action] = @acportal_portal_action if @acportal_portal_action

  cmd = Aethyr::Core::Actions::Acportal::AcportalCommand.new(@acportal_player, **data)
  cmd.action
end

###############################################################################
# Then steps                                                                  #
###############################################################################
Then('Admin.acreate should have been called for acportal') do
  assert(!@acportal_admin_calls.empty?,
    "Expected Admin.acreate to have been called at least once, but it was not.")
end

Then('the acportal object portal_action should not have been changed') do
  assert(!@acportal_created_object.info.portal_action_was_set,
    "Expected portal_action NOT to be set on the object, but it was set to: #{@acportal_created_object.info.portal_action.inspect}")
end

Then('the acportal object portal_action should be :push') do
  assert_equal(:push, @acportal_created_object.info.portal_action,
    "Expected portal_action to be :push but got #{@acportal_created_object.info.portal_action.inspect}")
end

Then('the acportal object portal_action should be :pull') do
  assert_equal(:pull, @acportal_created_object.info.portal_action,
    "Expected portal_action to be :pull but got #{@acportal_created_object.info.portal_action.inspect}")
end
