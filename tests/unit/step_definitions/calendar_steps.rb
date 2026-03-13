# frozen_string_literal: true
###############################################################################
# Step definitions for Calendar in-game date/time tracking.                   #
# Exercises lib/aethyr/core/objects/info/calendar.rb                          #
###############################################################################
require 'test/unit/assertions'
require 'aethyr/core/objects/info/calendar'

World(Test::Unit::Assertions)

###############################################################################
# World module – scenario-scoped state with cal_ prefix                       #
###############################################################################
module CalendarWorld
  attr_accessor :cal_instance, :cal_alerts, :cal_time_of_day_result,
                :cal_ordinal_day_result, :cal_time_at_result,
                :cal_date_at_result, :cal_saved_manager
end
World(CalendarWorld)

###############################################################################
# Lightweight $manager double for tick(false) tests                           #
###############################################################################
class CalendarMockManager
  attr_reader :alerts

  def initialize
    @alerts = []
  end

  def alert_all(msg)
    @alerts << msg
  end
end

###############################################################################
# Construction                                                                #
###############################################################################
Given('I create a new Calendar') do
  @cal_instance = Calendar.new
end

Given('I create a new Calendar with stubbed manager') do
  @cal_saved_manager = $manager
  $manager = CalendarMockManager.new
  @cal_alerts = $manager.alerts
  @cal_instance = Calendar.new
end

After do
  if @cal_saved_manager
    $manager = @cal_saved_manager
    @cal_saved_manager = nil
  end
end

###############################################################################
# Instance-variable manipulation helpers                                      #
###############################################################################
When('I set the calendar hour to {int}') do |val|
  @cal_instance.instance_variable_set(:@hour, val)
end

When('I set the calendar day to {int}') do |val|
  @cal_instance.instance_variable_set(:@day, val)
end

When('I set the calendar month to {int}') do |val|
  @cal_instance.instance_variable_set(:@month, val)
end

When('I set the calendar year to {int}') do |val|
  @cal_instance.instance_variable_set(:@year, val)
end

###############################################################################
# Construction assertions                                                     #
###############################################################################
Then('the calendar hour should be a non-negative integer') do
  assert_kind_of(Integer, @cal_instance.hour)
  assert(@cal_instance.hour >= 0, "hour should be >= 0, got #{@cal_instance.hour}")
end

Then('the calendar day should be between {int} and {int}') do |lo, hi|
  assert(@cal_instance.day >= lo && @cal_instance.day <= hi,
         "day should be #{lo}..#{hi}, got #{@cal_instance.day}")
end

Then('the calendar month should be between {int} and {int}') do |lo, hi|
  assert(@cal_instance.month >= lo && @cal_instance.month <= hi,
         "month should be #{lo}..#{hi}, got #{@cal_instance.month}")
end

Then('the calendar year should be a non-negative integer') do
  assert_kind_of(Integer, @cal_instance.year)
  assert(@cal_instance.year >= 0, "year should be >= 0, got #{@cal_instance.year}")
end

###############################################################################
# Public method assertions: time, date, to_s                                  #
###############################################################################
Then('the calendar time string should be {string}') do |expected|
  assert_equal(expected, @cal_instance.time)
end

Then('the calendar date string should be {string}') do |expected|
  assert_equal(expected, @cal_instance.date)
end

Then('the calendar to_s should be {string}') do |expected|
  assert_equal(expected, @cal_instance.to_s)
end

###############################################################################
# day? / night?                                                               #
###############################################################################
Then('the calendar should report daytime') do
  assert(@cal_instance.day?, "Expected day? to be true for hour #{@cal_instance.hour}")
  assert(!@cal_instance.night?, "Expected night? to be false for hour #{@cal_instance.hour}")
end

Then('the calendar should report nighttime') do
  assert(!@cal_instance.day?, "Expected day? to be false for hour #{@cal_instance.hour}")
  assert(@cal_instance.night?, "Expected night? to be true for hour #{@cal_instance.hour}")
end

Then('the calendar night? should be false') do
  assert_equal(false, @cal_instance.night?)
end

Then('the calendar night? should be true') do
  assert_equal(true, @cal_instance.night?)
end

###############################################################################
# time_at / date_at                                                           #
###############################################################################
When('I call time_at with a known timestamp') do
  # Use a timestamp a few hours after the epoch
  ts = Calendar::StartTime + 3600
  @cal_time_at_result = @cal_instance.time_at(ts)
end

Then('the time_at result should be a non-empty string') do
  assert_kind_of(String, @cal_time_at_result)
  assert(!@cal_time_at_result.empty?, 'time_at should return a non-empty string')
end

When('I call date_at with a known timestamp') do
  ts = Calendar::StartTime + 86400
  @cal_date_at_result = @cal_instance.date_at(ts)
end

Then('the date_at result should match the ordinal date pattern') do
  assert_match(/\d+\w* of \w+, \d+/, @cal_date_at_result)
end

When('I call date_at with timestamp {int}') do |ts|
  @cal_date_at_result = @cal_instance.date_at(ts)
end

Then('the date_at result should be {string}') do |expected|
  assert_equal(expected, @cal_date_at_result)
end

###############################################################################
# tick(false) – hour change with time_change messages                         #
###############################################################################

# Helper: forces @last_hour to differ from the target hour, stubs Time.now
# so tick calculates the desired hour, then calls tick(false).
When('I force the calendar hour to differ and tick with hour {int}') do |target_hour|
  # Set @last_hour to something different from target_hour
  @cal_instance.instance_variable_set(:@last_hour, target_hour == 0 ? 99 : target_hour - 1)

  # Keep day/year the same to avoid triggering those alerts
  current_day = @cal_instance.day
  current_year = @cal_instance.year
  @cal_instance.instance_variable_set(:@last_day, nil)
  @cal_instance.instance_variable_set(:@last_year, nil)

  # Stub Time.now so tick computes the target hour
  # hour = (Time.now.to_i - StartTime) / 60 % 60
  # We need: (fake_time - StartTime) / 60 % 60 == target_hour
  fake_time = Calendar::StartTime + (target_hour * 60)
  time_stub = Object.new
  time_stub.define_singleton_method(:to_i) { fake_time }

  original_time_now = Time.method(:now)
  Time.define_singleton_method(:now) { time_stub }

  begin
    # Reset day/year tracking to match what tick will compute so only hour alert fires
    computed_day = (fake_time - Calendar::StartTime) / 60 / 60 % 24 + 1
    computed_month = (fake_time - Calendar::StartTime) / 60 / 60 / 24 % 12
    computed_year = (fake_time - Calendar::StartTime) / 60 / 60 / 24 / 12
    @cal_instance.instance_variable_set(:@last_day, computed_day)
    @cal_instance.instance_variable_set(:@last_year, computed_year)

    $manager.alerts.clear if $manager.respond_to?(:alerts)
    @cal_instance.tick(false)
  ensure
    Time.define_singleton_method(:now, &original_time_now)
  end
end

Then('the manager should have received the midnight alert') do
  assert(@cal_alerts.any? { |m| m.include?('darkness of midnight') },
         "Expected midnight alert, got: #{@cal_alerts.inspect}")
end

Then('the manager should have received the morning-approaches alert') do
  assert(@cal_alerts.any? { |m| m.include?('dark shadows begin to turn grey') },
         "Expected morning-approaches alert, got: #{@cal_alerts.inspect}")
end

Then('the manager should have received the dawn alert') do
  assert(@cal_alerts.any? { |m| m.include?('dawn breaks') },
         "Expected dawn alert, got: #{@cal_alerts.inspect}")
end

Then('the manager should have received the midday alert') do
  assert(@cal_alerts.any? { |m| m.include?('sun stands high') },
         "Expected midday alert, got: #{@cal_alerts.inspect}")
end

Then('the manager should have received the sunset alert') do
  assert(@cal_alerts.any? { |m| m.include?('sun touches the horizon') },
         "Expected sunset alert, got: #{@cal_alerts.inspect}")
end

Then('the manager should have received the stars alert') do
  assert(@cal_alerts.any? { |m| m.include?('stars glimmer') },
         "Expected stars alert, got: #{@cal_alerts.inspect}")
end

Then('the manager should not have received any alert') do
  assert(@cal_alerts.empty?,
         "Expected no alerts, got: #{@cal_alerts.inspect}")
end

###############################################################################
# tick(false) – day change                                                    #
###############################################################################
When('I force the calendar day to differ and tick') do
  # Set @last_day to something that won't match whatever tick computes
  @cal_instance.instance_variable_set(:@last_day, -1)
  # Keep hour/year the same
  @cal_instance.instance_variable_set(:@last_hour, @cal_instance.hour)
  @cal_instance.instance_variable_set(:@last_year, @cal_instance.year)

  $manager.alerts.clear if $manager.respond_to?(:alerts)
  @cal_instance.tick(false)
end

Then('the manager should have received the day-change alert') do
  assert(@cal_alerts.any? { |m| m.include?('midnight passes') },
         "Expected day-change alert, got: #{@cal_alerts.inspect}")
end

###############################################################################
# tick(false) – year change                                                   #
###############################################################################
When('I force the calendar year to differ and tick') do
  # Set @last_year to something that won't match
  @cal_instance.instance_variable_set(:@last_year, -1)
  # Keep hour/day the same
  @cal_instance.instance_variable_set(:@last_hour, @cal_instance.hour)
  @cal_instance.instance_variable_set(:@last_day, @cal_instance.day)

  $manager.alerts.clear if $manager.respond_to?(:alerts)
  @cal_instance.tick(false)
end

Then('the manager should have received the year-change alert') do
  assert(@cal_alerts.any? { |m| m.include?('Happy new year') },
         "Expected year-change alert, got: #{@cal_alerts.inspect}")
end

###############################################################################
# time_of_day – private method tested directly via send                       #
###############################################################################
When('I call time_of_day with hour {int}') do |hour|
  @cal_time_of_day_result = @cal_instance.send(:time_of_day, hour)
end

Then('the time_of_day result should be {string}') do |expected|
  assert_equal(expected, @cal_time_of_day_result)
end

###############################################################################
# ordinal_day – private method tested directly via send                       #
###############################################################################
When('I call ordinal_day with day {int}') do |day|
  @cal_ordinal_day_result = @cal_instance.send(:ordinal_day, day)
end

Then('the ordinal_day result should be {string}') do |expected|
  assert_equal(expected, @cal_ordinal_day_result)
end
