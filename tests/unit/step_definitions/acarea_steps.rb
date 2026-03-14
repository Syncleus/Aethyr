# frozen_string_literal: true
###############################################################################
# Step definitions for AcareaCommand action coverage.                         #
###############################################################################
require 'test/unit/assertions'
require 'ostruct'
require 'aethyr/core/actions/commands/acarea'

World(Test::Unit::Assertions)

###############################################################################
# World module – scenario-scoped state                                        #
###############################################################################
module AcareaWorld
  attr_accessor :acarea_player, :acarea_room
end
World(AcareaWorld)

###############################################################################
# Lightweight doubles                                                         #
###############################################################################

# Recording player double that captures output messages.
class AcareaTestPlayer
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

# Minimal room double.
class AcareaTestRoom
  attr_accessor :goid, :name

  def initialize
    @goid = "room_goid_1"
    @name = "Test Room"
  end
end

# Minimal area double returned by create_object.
class AcareaTestArea
  attr_accessor :name

  def initialize(name)
    @name = name
  end

  def to_s
    "Area<#{@name}>"
  end
end

###############################################################################
# Given steps                                                                 #
###############################################################################
Given('a stubbed AcareaCommand environment') do
  @acarea_player = AcareaTestPlayer.new
  @acarea_room   = AcareaTestRoom.new

  # Ensure the Area constant exists (stubbed).
  unless defined?(::Area)
    Object.const_set(:Area, Class.new)
  end

  room_ref   = @acarea_room

  mgr = Object.new

  mgr.define_singleton_method(:get_object) do |_goid|
    room_ref
  end

  mgr.define_singleton_method(:create_object) do |_klass, _a, _b, _c, opts|
    AcareaTestArea.new(opts[:@name])
  end

  $manager = mgr
end

###############################################################################
# When steps                                                                  #
###############################################################################
When('the AcareaCommand action is invoked with name {string}') do |area_name|
  cmd = Aethyr::Core::Actions::Acarea::AcareaCommand.new(
    @acarea_player, name: area_name
  )
  cmd.action
end

###############################################################################
# Then steps                                                                  #
###############################################################################
Then('the acarea player should see {string}') do |expected|
  match = @acarea_player.messages.any? { |m| m.include?(expected) }
  assert(match,
    "Expected player output containing #{expected.inspect}, got: #{@acarea_player.messages.inspect}")
end
