# features/step_definitions/help_entry_steps.rb
# frozen_string_literal: true

###############################################################################
# Step-definitions that verify Aethyr::Core::Help::HelpEntry invariants.      #
###############################################################################
require 'test/unit/assertions'
require 'aethyr/core/help/help_entry'

World(Test::Unit::Assertions)

# Utility to stash the most-recently created entry or captured exception
module HelpEntryWorld
  attr_accessor :entry, :exception
end
World(HelpEntryWorld)

# --------------------------------------------------------------------------- #
# Construction helpers                                                        #
# --------------------------------------------------------------------------- #
Given('I create a content help entry with:') do |table|
  # Convert the data-table to a Hash with symbol keys for brevity
  attrs = table.rows_hash.transform_keys(&:to_sym)
  @entry = Aethyr::Core::Help::HelpEntry.new(
    attrs.fetch(:topic),
    content:         attrs.fetch(:content),
    syntax_formats:  Array(attrs.fetch(:syntax))
  )
end

Given('I create a redirect help entry from {string} to {string}') do |from, to|
  @entry = Aethyr::Core::Help::HelpEntry.new(from, redirect: to)
end

When('I attempt to create a help entry with:') do |table|
  attrs = table.rows_hash.transform_keys(&:to_sym)
  begin
    Aethyr::Core::Help::HelpEntry.new(attrs.fetch(:topic), content: attrs[:content])
  rescue => e
    @exception = e
  end
end

# --------------------------------------------------------------------------- #
# Assertions                                                                  #
# --------------------------------------------------------------------------- #
Then('the help entry should NOT be a redirect') do
  assert(@entry && !@entry.redirect?,
         'Expected a non-redirect HelpEntry but entry redirects')
end

Then('the help entry should be a redirect to {string}') do |dest|
  assert(@entry.redirect?, 'Expected entry to be a redirect')
  assert_equal(dest, @entry.redirect)
end

Then('the help-entry creation should raise RuntimeError with message {string}') do |msg|
  assert(@exception, 'Expected an exception but none was captured')
  assert_instance_of(RuntimeError, @exception)
  assert_match(/#{Regexp.escape(msg)}/, @exception.message)
end
