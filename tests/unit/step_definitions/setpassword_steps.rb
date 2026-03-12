# frozen_string_literal: true
###############################################################################
# Step definitions for SetpasswordCommand action coverage.                    #
###############################################################################
require 'test/unit/assertions'
require 'ostruct'

World(Test::Unit::Assertions)

###############################################################################
# World module -- scenario-scoped state                                       #
###############################################################################
module SetpasswordWorld
  attr_accessor :setpwd_player, :setpwd_new_password, :setpwd_check_result,
                :setpwd_expect_passwords, :setpwd_manager,
                :setpwd_settings_called
end
World(SetpasswordWorld)

###############################################################################
# Lightweight IO double                                                       #
###############################################################################
class SetpwdMockIo
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
class SetpwdMockPlayer
  attr_accessor :container, :name
  attr_reader :messages, :io

  def initialize
    @container = "setpwd_room_1"
    @name      = "SetpwdTestPlayer"
    @messages  = []
    @io        = SetpwdMockIo.new
    @expect_passwords = []
  end

  def output(msg, *_args)
    @messages << msg.to_s
  end

  # Store the queue of passwords that expect blocks will receive.
  def setpwd_expect_passwords=(list)
    @expect_passwords = list.dup
  end

  # When expect is called, immediately invoke the block with the next
  # password from the queue, simulating user input.
  def expect(&block)
    pw = @expect_passwords.shift
    block.call(pw) if block
  end
end

###############################################################################
# Lightweight manager double                                                  #
###############################################################################
class SetpwdMockManager
  attr_reader :set_password_calls

  def initialize(check_result: false)
    @check_result       = check_result
    @set_password_calls = []
  end

  def check_password_result=(val)
    @check_result = val
  end

  def get_object(_goid)
    OpenStruct.new(name: "TestRoom", goid: "setpwd_room_1")
  end

  def set_password(player, password)
    @set_password_calls << { player: player, password: password }
  end

  def check_password(_name, _password)
    @check_result
  end
end

###############################################################################
# Stub Settings module -- must be defined before the command is loaded so     #
# that runtime calls to Settings.setpassword find our double.                 #
###############################################################################
module Settings
  @setpwd_calls = []

  class << self
    attr_reader :setpwd_calls

    def setpassword(command, player, room)
      @setpwd_calls << { command: command, player: player, room: room }
    end

    def setpwd_reset!
      @setpwd_calls = []
    end
  end
end

###############################################################################
# Now load the actual command under test (pulls in the real class hierarchy)  #
###############################################################################
require 'aethyr/core/actions/commands/setpassword'

###############################################################################
# Given steps                                                                 #
###############################################################################
Given('a stubbed setpwd environment') do
  @setpwd_player = SetpwdMockPlayer.new
  @setpwd_new_password = nil
  @setpwd_check_result = false
  @setpwd_expect_passwords = []
  @setpwd_settings_called = false

  @setpwd_manager = SetpwdMockManager.new
  $manager = @setpwd_manager

  Settings.setpwd_reset!
end

Given('the setpwd new_password is {string}') do |pw|
  @setpwd_new_password = pw
end

Given('the setpwd has no new_password') do
  @setpwd_new_password = nil
end

Given('the setpwd old password check will fail') do
  @setpwd_check_result = false
end

Given('the setpwd old password check will succeed') do
  @setpwd_check_result = true
end

Given('the setpwd expect passwords are {string}') do |csv|
  @setpwd_expect_passwords = csv.split(",").map(&:strip)
end

###############################################################################
# When steps                                                                  #
###############################################################################
When('the setpwd action is invoked') do
  @setpwd_manager.check_password_result = @setpwd_check_result
  @setpwd_player.setpwd_expect_passwords = @setpwd_expect_passwords

  data = {}
  data[:new_password] = @setpwd_new_password unless @setpwd_new_password.nil?

  cmd = Aethyr::Core::Actions::Setpassword::SetpasswordCommand.new(
    @setpwd_player, **data
  )
  cmd.action
end

###############################################################################
# Then steps                                                                  #
###############################################################################
Then('the setpwd player should see {string}') do |fragment|
  match = @setpwd_player.messages.any? { |m| m.include?(fragment) }
  assert(match,
    "Expected player output containing #{fragment.inspect}, got: #{@setpwd_player.messages.inspect}")
end

Then('the setpwd manager set_password should have been called') do
  assert(!@setpwd_manager.set_password_calls.empty?,
    "Expected $manager.set_password to have been called, but it was not.")
end

Then('the setpwd settings setpassword should have been called') do
  assert(!Settings.setpwd_calls.empty?,
    "Expected Settings.setpassword to have been called, but it was not.")
end

Then('the setpwd io echo_on should have been called') do
  assert(@setpwd_player.io.echo_on_count > 0,
    "Expected player.io.echo_on to have been called, but it was not.")
end

Then('the setpwd io echo_off should have been called') do
  assert(@setpwd_player.io.echo_off_count > 0,
    "Expected player.io.echo_off to have been called, but it was not.")
end
