# frozen_string_literal: true
# -----------------------------------------------------------------------------
# Step definitions for Paginator feature
#
# Exercises lib/aethyr/core/render/paginator.rb directly.
# -----------------------------------------------------------------------------
require 'test/unit/assertions'

World(Test::Unit::Assertions)

# ---------------------------------------------------------------------------
# World module – all attributes prefixed with pag_
# ---------------------------------------------------------------------------
module PaginatorWorld
  attr_accessor :pag_paginator, :pag_page, :pag_other_page,
                :pag_visited_pages, :pag_items
end
World(PaginatorWorld)

# ---------------------------------------------------------------------------
# Background
# ---------------------------------------------------------------------------
Given('I require the paginator library') do
  require 'aethyr/core/render/paginator'
end

# ---------------------------------------------------------------------------
# Given steps
# ---------------------------------------------------------------------------
Given('a paginator with {int} items and {int} per page') do |total, per_page|
  data = (1..total).map { |i| "item#{i}" }
  self.pag_paginator = Paginator.new(total, per_page) do |offset, pp|
    data[offset, pp]
  end
end

Given('a paginator with {int} items and {int} per page using arity-1 block') do |total, per_page|
  data = (1..total).map { |i| "item#{i}" }
  self.pag_paginator = Paginator.new(total, per_page) do |offset|
    data[offset, per_page]
  end
end

Given('a paginator with {int} items and {int} per page using arity-2 block') do |total, per_page|
  data = (1..total).map { |i| "item#{i}" }
  self.pag_paginator = Paginator.new(total, per_page) do |offset, pp|
    data[offset, pp]
  end
end

# ---------------------------------------------------------------------------
# When steps
# ---------------------------------------------------------------------------
When('I get the first page') do
  self.pag_page = pag_paginator.first
end

When('I get the last page') do
  self.pag_page = pag_paginator.last
end

When('I iterate over all pages') do
  self.pag_visited_pages = []
  pag_paginator.each { |page| pag_visited_pages << page }
end

When('I get page {int}') do |number|
  self.pag_page = pag_paginator.page(number)
end

When('I also get page {int}') do |number|
  self.pag_other_page = pag_paginator.page(number)
end

# ---------------------------------------------------------------------------
# Then steps – constructor
# ---------------------------------------------------------------------------
Then('creating a Paginator without a block should raise MissingSelectError') do
  assert_raises(Paginator::MissingSelectError) do
    Paginator.new(10, 5)
  end
end

# ---------------------------------------------------------------------------
# Then steps – page number
# ---------------------------------------------------------------------------
Then('the page number should be {int}') do |expected|
  assert_equal(expected, pag_page.number)
end

# ---------------------------------------------------------------------------
# Then steps – each / iteration
# ---------------------------------------------------------------------------
Then('I should have visited {int} pages') do |expected|
  assert_equal(expected, pag_visited_pages.size)
end

Then('the visited page numbers should be {string}') do |expected_str|
  expected = expected_str.split(',').map(&:to_i)
  actual = pag_visited_pages.map(&:number)
  assert_equal(expected, actual)
end

# ---------------------------------------------------------------------------
# Then steps – Page#empty?
# ---------------------------------------------------------------------------
Then('the page should not be empty') do
  assert(!pag_page.empty?, 'Expected page not to be empty')
end

Then('the page should be empty') do
  assert(pag_page.empty?, 'Expected page to be empty')
end

# ---------------------------------------------------------------------------
# Then steps – Page#prev? / Page#prev
# ---------------------------------------------------------------------------
Then('prev? should be false') do
  assert_equal(false, pag_page.prev?)
end

Then('prev? should be true') do
  assert_equal(true, pag_page.prev?)
end

Then('prev should be nil') do
  assert_nil(pag_page.prev)
end

Then('prev should be page {int}') do |expected_number|
  prev_page = pag_page.prev
  assert_not_nil(prev_page, 'Expected prev to return a page')
  assert_equal(expected_number, prev_page.number)
end

# ---------------------------------------------------------------------------
# Then steps – Page#next? / Page#next
# ---------------------------------------------------------------------------
Then('next? should be false') do
  assert_equal(false, pag_page.next?)
end

Then('next? should be true') do
  assert_equal(true, pag_page.next?)
end

Then('next should be nil') do
  assert_nil(pag_page.next)
end

Then('next should be page {int}') do |expected_number|
  next_page = pag_page.next
  assert_not_nil(next_page, 'Expected next to return a page')
  assert_equal(expected_number, next_page.number)
end

# ---------------------------------------------------------------------------
# Then steps – Page#first_item_number / Page#last_item_number
# ---------------------------------------------------------------------------
Then('first_item_number should be {int}') do |expected|
  assert_equal(expected, pag_page.first_item_number)
end

Then('last_item_number should be {int}') do |expected|
  assert_equal(expected, pag_page.last_item_number)
end

# ---------------------------------------------------------------------------
# Then steps – Page#==
# ---------------------------------------------------------------------------
Then('the two pages should be equal') do
  assert_equal(pag_page, pag_other_page)
end

Then('the two pages should not be equal') do
  assert(pag_page != pag_other_page,
         "Expected pages #{pag_page.number} and #{pag_other_page.number} not to be equal")
end

# ---------------------------------------------------------------------------
# Then steps – Page#each
# ---------------------------------------------------------------------------
Then('iterating the page should yield {int} items') do |expected|
  collected = []
  pag_page.each { |item| collected << item }
  assert_equal(expected, collected.size)
end

# ---------------------------------------------------------------------------
# Then steps – Page#method_missing (delegation to pager)
# ---------------------------------------------------------------------------
Then('calling per_page on the page should return {int}') do |expected|
  assert_equal(expected, pag_page.per_page)
end

Then('calling number_of_pages on the page should return {int}') do |expected|
  assert_equal(expected, pag_page.number_of_pages)
end

Then('calling a nonexistent method on the page should raise NoMethodError') do
  assert_raises(NoMethodError) do
    pag_page.totally_nonexistent_method_xyz
  end
end

# ---------------------------------------------------------------------------
# Then steps – arity block items
# ---------------------------------------------------------------------------
Then('the page items should be {string}') do |expected_str|
  expected = expected_str.split(',')
  assert_equal(expected, pag_page.items)
end
