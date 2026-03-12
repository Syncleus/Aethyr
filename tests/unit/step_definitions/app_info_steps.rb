# frozen_string_literal: true
require 'test/unit/assertions'

World(Test::Unit::Assertions)

Given('I require the app_info library') do
  # The gemspec loads app_info.rb before SimpleCov starts, so `require` is a
  # no-op by the time Cucumber runs.  `load` forces re-execution so that
  # SimpleCov can track the lines.
  load File.expand_path('lib/aethyr/app_info.rb')
end

Then('the Aethyr module should be defined') do
  assert(Object.const_defined?(:Aethyr),
         'Expected the Aethyr module to be defined')
end

Then('the Aethyr VERSION constant should equal {string}') do |expected|
  actual = Aethyr::VERSION
  assert_equal(expected, actual,
               "Expected Aethyr::VERSION to equal #{expected.inspect} but got #{actual.inspect}")
end
