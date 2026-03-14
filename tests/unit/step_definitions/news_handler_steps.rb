# frozen_string_literal: true
###############################################################################
# Step definitions for NewsHandler player_input coverage.                     #
#                                                                             #
# These steps exercise every regex branch inside                              #
# NewsHandler#player_input (lines 67-91 of news.rb) to achieve >97% line     #
# coverage.                                                                   #
#                                                                             #
# All collaborators ($manager, player) are stubbed to isolate the handler     #
# logic under test.                                                           #
###############################################################################

require 'test/unit/assertions'
require 'aethyr/core/input_handlers/news'
require_relative '../support/test_helpers'

World(Test::Unit::Assertions)

###############################################################################
# World module – scenario-scoped state                                        #
###############################################################################
module NewsHandlerWorld
  attr_accessor :nh_player, :nh_handler, :nh_captured_actions
end
World(NewsHandlerWorld)

###############################################################################
# Given steps                                                                 #
###############################################################################
Given('a stubbed NewsHandler environment') do
  @nh_player = ::Aethyr::Core::Objects::MockPlayer.new("NewsReader")

  @nh_handler = Aethyr::Core::Commands::News::NewsHandler.new(@nh_player)

  # Lightweight manager stub that captures submitted actions.
  mgr = Object.new
  captured = []
  mgr.define_singleton_method(:submit_action) { |action| captured << action }
  $manager = mgr

  @nh_captured_actions = captured
end

###############################################################################
# When steps                                                                  #
###############################################################################
When('the news handler input is {string}') do |input|
  @nh_captured_actions.clear
  @nh_handler.player_input(input: input)
end

###############################################################################
# Then steps                                                                  #
###############################################################################
Then('the news handler should have submitted {int} action(s)') do |count|
  assert_equal(count, @nh_captured_actions.size,
    "Expected #{count} submitted action(s), got #{@nh_captured_actions.size}")
end

Then('the submitted news action should be a LatestNewsCommand') do
  action = @nh_captured_actions.last
  assert_instance_of(
    Aethyr::Core::Actions::LatestNews::LatestNewsCommand,
    action,
    "Expected LatestNewsCommand but got #{action.class}"
  )
end

Then('the submitted news action should be a ReadPostCommand') do
  action = @nh_captured_actions.last
  assert_instance_of(
    Aethyr::Core::Actions::ReadPost::ReadPostCommand,
    action,
    "Expected ReadPostCommand but got #{action.class}"
  )
end

Then('the submitted news action should be a WritePostCommand') do
  action = @nh_captured_actions.last
  assert_instance_of(
    Aethyr::Core::Actions::WritePost::WritePostCommand,
    action,
    "Expected WritePostCommand but got #{action.class}"
  )
end

Then('the submitted news action should be a ListUnreadCommand') do
  action = @nh_captured_actions.last
  assert_instance_of(
    Aethyr::Core::Actions::ListUnread::ListUnreadCommand,
    action,
    "Expected ListUnreadCommand but got #{action.class}"
  )
end

Then('the submitted news action should be a DeletePostCommand') do
  action = @nh_captured_actions.last
  assert_instance_of(
    Aethyr::Core::Actions::DeletePost::DeletePostCommand,
    action,
    "Expected DeletePostCommand but got #{action.class}"
  )
end

Then('the submitted news action should be an AllCommand') do
  action = @nh_captured_actions.last
  assert_instance_of(
    Aethyr::Core::Actions::All::AllCommand,
    action,
    "Expected AllCommand but got #{action.class}"
  )
end

Then('the submitted news action post_id should be {string}') do |expected|
  action = @nh_captured_actions.last
  assert_equal(expected, action[:post_id],
    "Expected post_id '#{expected}', got '#{action[:post_id]}'")
end

Then('the submitted news action reply_to should be {string}') do |expected|
  action = @nh_captured_actions.last
  assert_equal(expected, action[:reply_to],
    "Expected reply_to '#{expected}', got '#{action[:reply_to]}'")
end

Then('the submitted news action should not have reply_to') do
  action = @nh_captured_actions.last
  assert_nil(action[:reply_to],
    "Expected reply_to to be nil, got #{action[:reply_to].inspect}")
end

Then('the submitted news action limit should be {int}') do |expected|
  action = @nh_captured_actions.last
  assert_equal(expected, action[:limit],
    "Expected limit #{expected}, got #{action[:limit]}")
end
