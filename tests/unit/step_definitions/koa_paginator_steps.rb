# frozen_string_literal: true
# -----------------------------------------------------------------------------
# Step definitions for KPaginator feature
#
# Exercises lib/aethyr/core/render/koa_paginator.rb which wraps Paginator
# to provide easy paging of multi-line messages.
# -----------------------------------------------------------------------------
require 'test/unit/assertions'

World(Test::Unit::Assertions)

# ---------------------------------------------------------------------------
# World module – all attributes prefixed with kpag_
# ---------------------------------------------------------------------------
module KPaginatorWorld
  attr_accessor :kpag_player, :kpag_message, :kpag_paginator, :kpag_result
end
World(KPaginatorWorld)

# ---------------------------------------------------------------------------
# Lightweight player double – only needs #page_height
# ---------------------------------------------------------------------------
KPagMockPlayer = Struct.new(:page_height)

# ---------------------------------------------------------------------------
# Background
# ---------------------------------------------------------------------------
Given('I require the koa_paginator library') do
  require 'aethyr/core/render/koa_paginator'
end

# ---------------------------------------------------------------------------
# Given steps
# ---------------------------------------------------------------------------
Given('a kpag player with page height {int}') do |height|
  self.kpag_player = KPagMockPlayer.new(height)
end

Given('a kpag message with {int} lines') do |count|
  self.kpag_message = (1..count).map { |i| "Line #{i}" }
end

# ---------------------------------------------------------------------------
# When steps
# ---------------------------------------------------------------------------
When('I create a kpag paginator') do
  self.kpag_paginator = KPaginator.new(kpag_player, kpag_message)
end

When('I call kpag more') do
  self.kpag_result = kpag_paginator.more
end

# ---------------------------------------------------------------------------
# Then steps
# ---------------------------------------------------------------------------
Then('kpag pages should be {int}') do |expected|
  assert_equal(expected, kpag_paginator.pages)
end

Then('kpag lines should be {int}') do |expected|
  assert_equal(expected, kpag_paginator.lines)
end

Then('kpag current should be {int}') do |expected|
  assert_equal(expected, kpag_paginator.current)
end

Then('kpag more? should be true') do
  assert(kpag_paginator.more?, 'Expected more? to be true')
end

Then('kpag more? should be false') do
  assert(!kpag_paginator.more?, 'Expected more? to be false')
end

Then('the kpag result should contain {string}') do |text|
  assert(kpag_result.include?(text),
         "Expected result to contain '#{text}' but got: #{kpag_result.inspect}")
end

Then('the kpag result should not contain {string}') do |text|
  assert(!kpag_result.include?(text),
         "Expected result NOT to contain '#{text}' but got: #{kpag_result.inspect}")
end

Then('the kpag result should end with a newline') do
  assert(kpag_result.end_with?("\r\n"),
         "Expected result to end with \\r\\n but got: #{kpag_result.inspect}")
end

Then('the kpag result should be {string}') do |expected|
  assert_equal(expected, kpag_result)
end

Then('the kpag result should be the no-more message') do
  assert_equal("There is no more.\r\n", kpag_result)
end
