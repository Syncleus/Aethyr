Feature: Calendar in-game date and time tracking
  The Calendar translates real-world UNIX time into game time using an
  epoch-based formula. It exposes hour, day, month, and year as well as
  human-readable descriptions of the time-of-day and ordinal dates.

  # --------------------------------------------------------------------------
  # Construction
  # --------------------------------------------------------------------------
  Scenario: Initializing a Calendar sets hour, day, month, and year
    Given I create a new Calendar
    Then the calendar hour should be a non-negative integer
    And the calendar day should be between 1 and 24
    And the calendar month should be between 0 and 11
    And the calendar year should be a non-negative integer

  # --------------------------------------------------------------------------
  # Public instance methods: time, date, to_s
  # --------------------------------------------------------------------------
  Scenario: time returns a formatted time string
    Given I create a new Calendar
    When I set the calendar hour to 16
    And I set the calendar month to 0
    Then the calendar time string should be "It is dawn in Aethyr."

  Scenario: date returns a formatted date string
    Given I create a new Calendar
    When I set the calendar day to 3
    And I set the calendar month to 2
    And I set the calendar year to 5
    Then the calendar date string should be "Today is the 3rd day of the Third Month in the year 5."

  Scenario: to_s returns a full date and time string
    Given I create a new Calendar
    When I set the calendar hour to 31
    And I set the calendar day to 12
    And I set the calendar month to 5
    And I set the calendar year to 10
    Then the calendar to_s should be "It is currently noon on the 12th day of the Sixth Month in the year 10."

  # --------------------------------------------------------------------------
  # day? and night?
  # --------------------------------------------------------------------------
  Scenario: day? returns true when hour is in daytime range
    Given I create a new Calendar
    When I set the calendar hour to 20
    Then the calendar should report daytime

  Scenario: day? returns false when hour is before dawn
    Given I create a new Calendar
    When I set the calendar hour to 10
    Then the calendar should report nighttime

  Scenario: day? returns false when hour is after dusk
    Given I create a new Calendar
    When I set the calendar hour to 50
    Then the calendar should report nighttime

  Scenario: night? is the inverse of day?
    Given I create a new Calendar
    When I set the calendar hour to 20
    Then the calendar night? should be false
    When I set the calendar hour to 50
    Then the calendar night? should be true

  # --------------------------------------------------------------------------
  # time_at and date_at with a specific timestamp
  # --------------------------------------------------------------------------
  Scenario: time_at returns time-of-day for a given timestamp
    Given I create a new Calendar
    When I call time_at with a known timestamp
    Then the time_at result should be a non-empty string

  Scenario: date_at returns a formatted date for a given timestamp
    Given I create a new Calendar
    When I call date_at with a known timestamp
    Then the date_at result should match the ordinal date pattern

  # --------------------------------------------------------------------------
  # tick(false) – hour change triggers time_change alert
  # --------------------------------------------------------------------------
  Scenario: tick with hour change at midnight sends alert
    Given I create a new Calendar with stubbed manager
    When I force the calendar hour to differ and tick with hour 0
    Then the manager should have received the midnight alert

  Scenario: tick with hour change at hour 10 sends approaching-morning alert
    Given I create a new Calendar with stubbed manager
    When I force the calendar hour to differ and tick with hour 10
    Then the manager should have received the morning-approaches alert

  Scenario: tick with hour change at hour 15 sends dawn alert
    Given I create a new Calendar with stubbed manager
    When I force the calendar hour to differ and tick with hour 15
    Then the manager should have received the dawn alert

  Scenario: tick with hour change at hour 30 sends midday alert
    Given I create a new Calendar with stubbed manager
    When I force the calendar hour to differ and tick with hour 30
    Then the manager should have received the midday alert

  Scenario: tick with hour change at hour 45 sends sunset alert
    Given I create a new Calendar with stubbed manager
    When I force the calendar hour to differ and tick with hour 45
    Then the manager should have received the sunset alert

  Scenario: tick with hour change at hour 50 sends stars alert
    Given I create a new Calendar with stubbed manager
    When I force the calendar hour to differ and tick with hour 50
    Then the manager should have received the stars alert

  Scenario: tick with hour change at non-special hour does not alert
    Given I create a new Calendar with stubbed manager
    When I force the calendar hour to differ and tick with hour 5
    Then the manager should not have received any alert

  # --------------------------------------------------------------------------
  # tick(false) – day change triggers day_change alert
  # --------------------------------------------------------------------------
  Scenario: tick with day change sends day-change alert
    Given I create a new Calendar with stubbed manager
    When I force the calendar day to differ and tick
    Then the manager should have received the day-change alert

  # --------------------------------------------------------------------------
  # tick(false) – year change triggers year_change alert
  # --------------------------------------------------------------------------
  Scenario: tick with year change sends year-change alert
    Given I create a new Calendar with stubbed manager
    When I force the calendar year to differ and tick
    Then the manager should have received the year-change alert

  # --------------------------------------------------------------------------
  # time_of_day – all branches
  # --------------------------------------------------------------------------
  Scenario Outline: time_of_day returns the correct description
    Given I create a new Calendar
    When I call time_of_day with hour <hour>
    Then the time_of_day result should be "<description>"

    Examples:
      | hour | description       |
      |    0 | midnight          |
      |    2 | midnight          |
      |    3 | midnight          |
      |    4 | after midnight    |
      |    7 | after midnight    |
      |   10 | after midnight    |
      |   11 | approaching dawn  |
      |   14 | approaching dawn  |
      |   15 | approaching dawn  |
      |   16 | dawn              |
      |   17 | early morning     |
      |   18 | morning           |
      |   19 | morning           |
      |   20 | morning           |
      |   21 | late morning      |
      |   25 | late morning      |
      |   26 | almost noon       |
      |   29 | almost noon       |
      |   30 | almost noon       |
      |   31 | noon              |
      |   32 | noon              |
      |   33 | late afternoon    |
      |   38 | late afternoon    |
      |   40 | late afternoon    |
      |   41 | nearing dusk      |
      |   43 | nearing dusk      |
      |   44 | nearing dusk      |
      |   45 | dusk              |
      |   46 | dusk              |
      |   47 | nighttime         |
      |   50 | nighttime         |
      |   55 | nighttime         |
      |   56 | nearly midnight   |
      |   59 | nearly midnight   |
      |   60 | nearly midnight   |
      |   61 | uh oh             |

  # --------------------------------------------------------------------------
  # ordinal_day – all branches
  # --------------------------------------------------------------------------
  Scenario Outline: ordinal_day returns the correct suffix
    Given I create a new Calendar
    When I call ordinal_day with day <day>
    Then the ordinal_day result should be "<expected>"

    Examples:
      | day | expected |
      |   1 | 1st      |
      |   2 | 2nd      |
      |   3 | 3rd      |
      |   4 | 4th      |
      |   5 | 5th      |
      |   6 | 6th      |
      |   7 | 7th      |
      |   8 | 8th      |
      |   9 | 9th      |
      |  10 | 10th     |
      |  11 | 11th     |
      |  12 | 12th     |
      |  13 | 13th     |
      |  14 | 14th     |
      |  20 | 20th     |
      |  21 | 21st     |
      |  22 | 22nd     |
      |  23 | 23rd     |
      |  24 | 24th     |

  # --------------------------------------------------------------------------
  # convert (exercised through date_at with explicit timestamp)
  # --------------------------------------------------------------------------
  Scenario: date_at with a specific timestamp exercises convert
    Given I create a new Calendar
    When I call date_at with timestamp 1205971200
    Then the date_at result should be "1st of First, 0"
