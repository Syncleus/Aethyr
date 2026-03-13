# frozen_string_literal: true
# -----------------------------------------------------------------------------
# Step definitions for HelpLibrary feature
#
# Exercises lib/aethyr/core/help/help_library.rb – the central registry for
# in-game help topics.
# -----------------------------------------------------------------------------
require 'test/unit/assertions'

World(Test::Unit::Assertions)

# ---------------------------------------------------------------------------
# World module – all attributes prefixed with hlib_
# ---------------------------------------------------------------------------
module HelpLibraryWorld
  attr_accessor :hlib_library, :hlib_entry, :hlib_entries, :hlib_result
end
World(HelpLibraryWorld)

# ---------------------------------------------------------------------------
# Lightweight mock entry – quacks like HelpEntry for the library's purposes.
# ---------------------------------------------------------------------------
HlibMockEntry = Struct.new(:topic, :redirect_flag, :redirect, :aliases,
                           :syntax_formats, :content, :see_also) do
  def redirect?
    redirect_flag
  end
end

# ---------------------------------------------------------------------------
# Background
# ---------------------------------------------------------------------------
Given('I require the help library') do
  require 'aethyr/core/help/help_library'
  self.hlib_library = Aethyr::Core::Help::HelpLibrary.new
end

# ---------------------------------------------------------------------------
# Given steps – single entry helpers
# ---------------------------------------------------------------------------
Given('a help entry mock with topic {string}') do |topic|
  self.hlib_entry = HlibMockEntry.new(topic, false, nil, [], [], "", [])
end

Given('help entry mocks with topics {string}, {string}, {string}') do |t1, t2, t3|
  self.hlib_entries = [t1, t2, t3].map do |t|
    HlibMockEntry.new(t, false, nil, [], [], "", [])
  end
end

Given('a renderable entry {string} with content {string} syntax {string} and no aliases or see_also') do |topic, content, syntax|
  self.hlib_entry = HlibMockEntry.new(topic, false, nil, [], [syntax], content, [])
  self.hlib_entries = (hlib_entries || []) + [hlib_entry]
end

Given('a redirect entry {string} that redirects to {string}') do |from, to|
  self.hlib_entry = HlibMockEntry.new(from, true, to, [], [], "", [])
  self.hlib_entries = (hlib_entries || []) + [hlib_entry]
end

Given('a renderable entry {string} with content {string} syntax {string} aliases {string}, {string} and no see_also') do |topic, content, syntax, a1, a2|
  self.hlib_entry = HlibMockEntry.new(topic, false, nil, [a1, a2], [syntax], content, [])
  self.hlib_entries = (hlib_entries || []) + [hlib_entry]
end

Given('a renderable entry {string} with content {string} syntax {string} no aliases and see_also {string}, {string}') do |topic, content, syntax, s1, s2|
  self.hlib_entry = HlibMockEntry.new(topic, false, nil, [], [syntax], content, [s1, s2])
  self.hlib_entries = (hlib_entries || []) + [hlib_entry]
end

# ---------------------------------------------------------------------------
# When steps
# ---------------------------------------------------------------------------
When('I register the help entry in the library') do
  hlib_library.entry_register(hlib_entry)
end

When('I register all the help entries in the library') do
  hlib_entries.each { |e| hlib_library.entry_register(e) }
end

When('I deregister the topic {string}') do |topic|
  hlib_library.entry_deregister(topic)
end

# ---------------------------------------------------------------------------
# Then steps – registration / lookup
# ---------------------------------------------------------------------------
Then('looking up topic {string} should return that entry') do |topic|
  assert_equal(hlib_entry, hlib_library.lookup_topic(topic))
end

Then('looking up topic {string} should return nil') do |topic|
  assert_nil(hlib_library.lookup_topic(topic))
end

# ---------------------------------------------------------------------------
# Then steps – search / topics
# ---------------------------------------------------------------------------
Then('searching for {string} should return {string} and {string}') do |term, t1, t2|
  results = hlib_library.search_topics(term)
  assert_includes(results, t1, "Expected search results to include '#{t1}'")
  assert_includes(results, t2, "Expected search results to include '#{t2}'")
  assert_equal(2, results.length, "Expected exactly 2 results but got #{results.inspect}")
end

Then('the library topics should contain {string}, {string}, and {string}') do |t1, t2, t3|
  topics = hlib_library.topics
  [t1, t2, t3].each do |t|
    assert_includes(topics, t, "Expected topics to include '#{t}'")
  end
end

# ---------------------------------------------------------------------------
# Then steps – render_topic
# ---------------------------------------------------------------------------
Then('rendering topic {string} should return the not-found message') do |topic|
  result = hlib_library.render_topic(topic)
  assert_equal("Topic #{topic} has no entry, try help with no arguments", result)
end

Then('rendering topic {string} should include {string}') do |topic, text|
  self.hlib_result = hlib_library.render_topic(topic)
  assert(hlib_result.include?(text),
         "Expected render output to include '#{text}' but got:\n#{hlib_result}")
end

Then('rendering topic {string} should not include {string}') do |topic, text|
  self.hlib_result = hlib_library.render_topic(topic)
  assert(!hlib_result.include?(text),
         "Expected render output NOT to include '#{text}' but got:\n#{hlib_result}")
end
