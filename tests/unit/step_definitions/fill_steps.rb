# frozen_string_literal: true
###############################################################################
# Step definitions for FillCommand action coverage.                           #
###############################################################################
require 'test/unit/assertions'
require 'ostruct'
require 'aethyr/core/actions/commands/fill'
require_relative '../support/test_helpers'

World(Test::Unit::Assertions)

###############################################################################
# World module – scenario-scoped state                                        #
###############################################################################
module FillWorld
  attr_accessor :fill_player, :fill_object_name, :fill_from_name,
                :fill_object_double, :fill_from_double
end
World(FillWorld)

###############################################################################
# Lightweight doubles                                                         #
###############################################################################

# Stub for LiquidContainer – defined at top-level so `is_a?` checks work.
unless defined?(::LiquidContainer)
  class ::LiquidContainer; end
end

# Recording player double that captures output messages.
class FillPlayer
  attr_accessor :container, :name, :goid
  attr_reader :messages

  def initialize
    @container = "fill_room_goid_1"
    @name      = "TestFiller"
    @goid      = "fill_player_goid_1"
    @messages  = []
  end

  def output(msg, *_args)
    @messages << msg.to_s
  end

  # search_inv returns the object/from double when the name matches,
  # nil otherwise. Controlled per-scenario via fill_inv_results.
  attr_accessor :fill_inv_results

  def search_inv(name)
    (@fill_inv_results || {})[name]
  end
end

# A generic non-liquid item double (does NOT inherit LiquidContainer).
class FillNonLiquidItem
  attr_accessor :name, :generic

  def initialize(name, generic = nil)
    @name    = name
    @generic = generic || name
  end
end

# A liquid container double (IS-A LiquidContainer).
class FillLiquidItem < ::LiquidContainer
  attr_accessor :name, :generic, :is_empty, :is_full

  def initialize(name, generic = nil, is_empty: false, is_full: false)
    @name     = name
    @generic  = generic || name
    @is_empty = is_empty
    @is_full  = is_full
  end

  def empty?
    @is_empty
  end

  def full?
    @is_full
  end
end

###############################################################################
# Given steps                                                                 #
###############################################################################
Given('a stubbed FillCommand environment') do
  @fill_player       = FillPlayer.new
  @fill_object_name  = nil
  @fill_from_name    = nil
  @fill_object_double = nil
  @fill_from_double   = nil

  # Provide a room object for $manager.get_object(player.container)
  room_obj = Object.new

  # room.find will be wired up per-scenario via fill_room_objects hash
  room_obj.instance_variable_set(:@fill_room_objects, {})

  def room_obj.fill_room_objects
    @fill_room_objects
  end

  def room_obj.find(name)
    @fill_room_objects[name]
  end

  @fill_room = room_obj

  # Build a stub manager
  mgr = Object.new
  fill_room_ref = room_obj
  player_ref    = @fill_player

  mgr.define_singleton_method(:get_object) do |goid|
    if goid == player_ref.container
      fill_room_ref
    end
  end

  $manager = mgr
end

Given('the fill object name is {string}') do |name|
  @fill_object_name = name
end

Given('the fill from name is {string}') do |name|
  @fill_from_name = name
end

# --- object not found --------------------------------------------------------
Given('the fill object is not found') do
  @fill_object_double = nil
  @fill_player.fill_inv_results = {}
  @fill_room.fill_room_objects.clear
end

# --- object is a non-liquid item ---------------------------------------------
Given('the fill object is a non-liquid item named {string}') do |display_name|
  item = FillNonLiquidItem.new(display_name)
  @fill_object_double = item
  @fill_player.fill_inv_results = { @fill_object_name => item }
end

# --- object is a liquid container (simple) -----------------------------------
Given('the fill object is a liquid container named {string}') do |display_name|
  item = FillLiquidItem.new(display_name)
  @fill_object_double = item
  @fill_player.fill_inv_results = (@fill_player.fill_inv_results || {}).merge(@fill_object_name => item)
end

# --- object is a liquid container with generic --------------------------------
Given('the fill object is a liquid container named {string} with generic {string}') do |display_name, generic|
  item = FillLiquidItem.new(display_name, generic)
  @fill_object_double = item
  @fill_player.fill_inv_results = (@fill_player.fill_inv_results || {}).merge(@fill_object_name => item)
end

# --- object is a full liquid container with generic ---------------------------
Given('the fill object is a full liquid container named {string} with generic {string}') do |display_name, generic|
  item = FillLiquidItem.new(display_name, generic, is_full: true)
  @fill_object_double = item
  @fill_player.fill_inv_results = (@fill_player.fill_inv_results || {}).merge(@fill_object_name => item)
end

# --- from is not found -------------------------------------------------------
Given('the fill from is not found') do
  @fill_from_double = nil
  # Make sure from isn't in inventory or room
  inv = @fill_player.fill_inv_results || {}
  inv.delete(@fill_from_name)
  @fill_player.fill_inv_results = inv
  @fill_room.fill_room_objects.delete(@fill_from_name)
end

# --- from is a non-liquid item -----------------------------------------------
Given('the fill from is a non-liquid item named {string}') do |display_name|
  item = FillNonLiquidItem.new(display_name)
  @fill_from_double = item
  @fill_player.fill_inv_results = (@fill_player.fill_inv_results || {}).merge(@fill_from_name => item)
end

# --- from is an empty liquid container with generic ---------------------------
Given('the fill from is an empty liquid container named {string} with generic {string}') do |display_name, generic|
  item = FillLiquidItem.new(display_name, generic, is_empty: true)
  @fill_from_double = item
  @fill_player.fill_inv_results = (@fill_player.fill_inv_results || {}).merge(@fill_from_name => item)
end

# --- from is a non-empty liquid container with generic ------------------------
Given('the fill from is a non-empty liquid container named {string} with generic {string}') do |display_name, generic|
  item = FillLiquidItem.new(display_name, generic, is_empty: false)
  @fill_from_double = item
  @fill_player.fill_inv_results = (@fill_player.fill_inv_results || {}).merge(@fill_from_name => item)
end

# --- object and from are the same item ----------------------------------------
Given('the fill object and from are the same liquid container named {string}') do |display_name|
  item = FillLiquidItem.new(display_name, display_name, is_empty: false, is_full: false)
  @fill_object_double = item
  @fill_from_double   = item
  # Both names resolve to the same object
  @fill_player.fill_inv_results = (@fill_player.fill_inv_results || {}).merge(
    @fill_object_name => item,
    @fill_from_name   => item
  )
end

###############################################################################
# When steps                                                                  #
###############################################################################
When('the FillCommand action is invoked') do
  data = {}
  data[:object] = @fill_object_name if @fill_object_name
  data[:from]   = @fill_from_name   if @fill_from_name

  cmd = Aethyr::Core::Actions::Fill::FillCommand.new(@fill_player, **data)
  cmd.action
end

###############################################################################
# Then steps                                                                  #
###############################################################################
Then('the fill player should see {string}') do |fragment|
  match = @fill_player.messages.any? { |m| m.include?(fragment) }
  assert(match,
    "Expected fill player output containing #{fragment.inspect}, got: #{@fill_player.messages.inspect}")
end
