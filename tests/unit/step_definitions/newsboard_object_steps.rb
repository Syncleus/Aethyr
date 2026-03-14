# frozen_string_literal: true

###############################################################################
# Step-definitions for Newsboard object scenarios.                             #
#                                                                              #
# Exercises the initialize method of                                           #
# lib/aethyr/extensions/objects/newsboard.rb (lines 16-22).                    #
###############################################################################
require 'test/unit/assertions'

World(Test::Unit::Assertions)

###############################################################################
# Minimal $manager stub – GameObject#initialize calls                          #
# $manager.existing_goid? to guarantee GOID uniqueness.                        #
###############################################################################
module NewsboardObjectWorld
  attr_accessor :newsboard_instance

  class NewsboardStubManager
    def existing_goid?(_goid)
      false
    end

    def submit_action(action)
      # no-op
    end
  end
end
World(NewsboardObjectWorld)

###############################################################################
# Steps                                                                        #
###############################################################################

Given('I require the Newsboard object library') do
  $manager ||= NewsboardObjectWorld::NewsboardStubManager.new
  require 'aethyr/extensions/objects/newsboard'
end

When('I create a new Newsboard object') do
  $manager ||= NewsboardObjectWorld::NewsboardStubManager.new
  self.newsboard_instance = Aethyr::Extensions::Objects::Newsboard.new
end

Then('the Newsboard name should be {string}') do |expected|
  assert_equal expected, newsboard_instance.name
end

Then('the Newsboard generic should be {string}') do |expected|
  assert_equal expected, newsboard_instance.generic
end

Then('the Newsboard alt_names should include {string}') do |expected|
  assert_includes newsboard_instance.alt_names, expected
end

Then('the Newsboard should not be movable') do
  assert_equal false, newsboard_instance.movable
end

Then('the Newsboard board_name should be {string}') do |expected|
  assert_equal expected, newsboard_instance.info.board_name
end

Then('the Newsboard announce_new should be {string}') do |expected|
  assert_equal expected, newsboard_instance.info.announce_new
end

Then('the Newsboard should be a kind of GameObject') do
  assert_kind_of Aethyr::Core::Objects::GameObject, newsboard_instance
end
