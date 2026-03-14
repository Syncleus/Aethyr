# frozen_string_literal: true
###############################################################################
# Step definitions for DeletemeCommand action coverage.                       #
###############################################################################
require 'test/unit/assertions'
require 'ostruct'

World(Test::Unit::Assertions)

###############################################################################
# World module -- scenario-scoped state                                       #
###############################################################################
module DeletemeWorld
  attr_accessor :delme_player, :delme_password, :delme_check_result,
                :delme_expect_input, :delme_manager, :delme_command
end
World(DeletemeWorld)

###############################################################################
# Lightweight IO double                                                       #
###############################################################################
class DelmeMockIo
  attr_reader :echo_off_count, :echo_on_count

  def initialize
    @echo_off_count = 0
    @echo_on_count  = 0
  end

  def echo_off
    @echo_off_count += 1
  end

  def echo_on
    @echo_on_count += 1
  end
end

###############################################################################
# Lightweight player double                                                   #
###############################################################################
class DelmeMockPlayer
  attr_accessor :container, :name
  attr_reader :messages, :io, :quit_count

  def initialize
    @container    = "delme_room_1"
    @name         = "DelmeTestPlayer"
    @messages     = []
    @io           = DelmeMockIo.new
    @quit_count   = 0
    @expect_input = nil
  end

  def output(msg, *_args)
    @messages << msg.to_s
  end

  def quit
    @quit_count += 1
  end

  # Store input that will be fed to the expect block.
  def delme_expect_input=(value)
    @expect_input = value
  end

  # When expect is called, immediately invoke the block with the stored
  # input, simulating the player typing a password.
  def expect(&block)
    block.call(@expect_input) if block && @expect_input
  end
end

###############################################################################
# Lightweight manager double                                                  #
###############################################################################
class DelmeMockManager
  attr_reader :delete_player_calls

  def initialize
    @check_result        = false
    @delete_player_calls = []
  end

  def check_password_result=(val)
    @check_result = val
  end

  def check_password(_name, _password)
    @check_result
  end

  def delete_player(name)
    @delete_player_calls << name
  end

  def get_object(_goid)
    OpenStruct.new(name: "TestRoom", goid: "delme_room_1")
  end
end

###############################################################################
# Stub Generic module -- captures calls to Generic.deleteme so we can        #
# assert the expect block invoked it.                                         #
###############################################################################
module Generic; end unless defined?(Generic)

Generic.instance_variable_set(:@delme_calls, []) unless Generic.instance_variable_defined?(:@delme_calls)

unless Generic.respond_to?(:deleteme)
  Generic.define_singleton_method(:deleteme) do |command|
    @delme_calls << command
  end
end

unless Generic.respond_to?(:delme_calls)
  Generic.define_singleton_method(:delme_calls) do
    @delme_calls
  end
end

unless Generic.respond_to?(:delme_reset!)
  Generic.define_singleton_method(:delme_reset!) do
    @delme_calls = []
  end
end

###############################################################################
# Now load the actual command under test                                      #
###############################################################################
require 'aethyr/core/actions/commands/deleteme'

###############################################################################
# Given steps                                                                 #
###############################################################################
Given('a stubbed delme environment') do
  @delme_player       = DelmeMockPlayer.new
  @delme_password     = nil
  @delme_check_result = false
  @delme_expect_input = nil

  @delme_manager = DelmeMockManager.new
  $manager = @delme_manager

  Generic.delme_reset!
end

Given('the delme password is {string}') do |pw|
  @delme_password = pw
end

Given('the delme has no password') do
  @delme_password = nil
end

Given('the delme password check will succeed') do
  @delme_check_result = true
end

Given('the delme password check will fail') do
  @delme_check_result = false
end

Given('the delme expect input is {string}') do |input|
  @delme_expect_input = input
end

###############################################################################
# When steps                                                                  #
###############################################################################
When('the delme action is invoked') do
  @delme_manager.check_password_result = @delme_check_result
  @delme_player.delme_expect_input = @delme_expect_input

  data = {}
  data[:password] = @delme_password unless @delme_password.nil?

  @delme_command = Aethyr::Core::Actions::Deleteme::DeletemeCommand.new(
    @delme_player, **data
  )
  @delme_command.action
end

###############################################################################
# Then steps                                                                  #
###############################################################################
Then('the delme player should see {string}') do |fragment|
  match = @delme_player.messages.any? { |m| m.include?(fragment) }
  assert(match,
    "Expected delme player output containing #{fragment.inspect}, got: #{@delme_player.messages.inspect}")
end

Then('the delme player quit should have been called') do
  assert(@delme_player.quit_count > 0,
    "Expected player.quit to have been called, but it was not.")
end

Then('the delme player quit should not have been called') do
  assert_equal(0, @delme_player.quit_count,
    "Expected player.quit NOT to have been called, but it was called #{@delme_player.quit_count} time(s).")
end

Then('the delme manager delete_player should have been called') do
  assert(!@delme_manager.delete_player_calls.empty?,
    "Expected $manager.delete_player to have been called, but it was not.")
end

Then('the delme manager delete_player should not have been called') do
  assert(@delme_manager.delete_player_calls.empty?,
    "Expected $manager.delete_player NOT to have been called, but it was.")
end

Then('the delme io echo_off should have been called') do
  assert(@delme_player.io.echo_off_count > 0,
    "Expected player.io.echo_off to have been called, but it was not.")
end

Then('the delme io echo_on should have been called') do
  assert(@delme_player.io.echo_on_count > 0,
    "Expected player.io.echo_on to have been called, but it was not.")
end

Then('the delme generic deleteme should have been called') do
  assert(!Generic.delme_calls.empty?,
    "Expected Generic.deleteme to have been called, but it was not.")
end
