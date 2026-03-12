Feature: Logger utility
  The Logger class provides buffered, file-backed logging with automatic
  log rotation when the log file exceeds a configurable size limit.

  Background:
    Given I require the Logger library

  Scenario: Logger class defines severity constants
    Then Logger::Ultimate should equal 3
    And Logger::Medium should equal 2
    And Logger::Normal should equal 1
    And Logger::Important should equal 0

  Scenario: Logger initialises with default parameters
    When I create a Logger with defaults
    Then the logger should exist

  Scenario: Logger initialises with custom parameters
    When I create a Logger with file "logs/test.log" buffer size 10 buffer time 60 and max size 1000
    Then the logger should exist

  Scenario: add returns nil when message is nil and no block given
    When I create a Logger with defaults
    And I call add with log_level 0 and nil message
    Then the logger should have 0 buffered entries

  Scenario: add uses block when message is nil and block is given
    When I create a Logger with defaults
    And I call add with log_level 0 and a block returning "block message"
    Then the logger should have 1 buffered entries

  Scenario: add buffers the message when log level qualifies
    When I create a Logger with defaults
    And I call add with log_level 0 and message "hello world"
    Then the logger should have 1 buffered entries

  Scenario: add ignores the message when log level is too high
    When I create a Logger with defaults
    And I call add with log_level 99 and message "should be ignored"
    Then the logger should have 0 buffered entries

  Scenario: add forces dump when dump_log is true
    When I create a Logger with a temporary log file
    And I call add with log_level 0 message "dumped" and dump_log true
    Then the temporary log file should contain "dumped"

  Scenario: add triggers dump when buffer exceeds size
    When I create a Logger with a temporary log file and buffer size 2
    And I call add with log_level 0 and message "msg1"
    And I call add with log_level 0 and message "msg2"
    And I call add with log_level 0 and message "msg3"
    Then the temporary log file should contain "msg1"

  Scenario: add triggers dump when buffer time is exceeded
    When I create a Logger with a temporary log file and zero buffer time
    And I call add with log_level 0 and message "timed"
    Then the temporary log file should contain "timed"

  Scenario: dump writes entries to the log file
    When I create a Logger with a temporary log file
    And I call add with log_level 0 and message "entry1"
    And I force dump on the logger
    Then the temporary log file should contain "entry1"

  Scenario: dump deletes an oversized log file before writing
    When I create a Logger with a temporary log file and max size 1
    And I write oversized content to the temporary log file
    And I call add with log_level 0 and message "after delete"
    And I force dump on the logger
    Then the temporary log file should contain "DELETED LOG FILE"

  Scenario: dump with empty entries still calls clear
    When I create a Logger with a temporary log file
    And I force dump on the logger
    Then the logger should have 0 buffered entries

  Scenario: clear empties the buffer
    When I create a Logger with defaults
    And I call add with log_level 0 and message "to be cleared"
    And I call clear on the logger
    Then the logger should have 0 buffered entries

  Scenario: << operator logs at Normal level
    When I create a Logger with defaults
    And I use the shovel operator with "shovel msg"
    Then the logger should have 1 buffered entries

  Scenario: Object#log method with dump_log-capable Logger
    When I set up a Logger as the global LOG
    And I call log on an object with message "obj log test"
    Then the global LOG should have buffered entries

  Scenario: Object#log method with non-dump_log Logger
    When I set up a non-dump_log Logger as the global LOG
    And I call log on an object with message "fallback log"
    Then the non-dump_log LOG should have received the message

  Scenario: Object#log initialises global LOG if unset
    When I clear the global LOG
    And I call log on an object with message "auto init"
    Then the global LOG should be a Logger instance

  Scenario: Compatibility patch activates when add lacks dump_log
    When I trigger the compatibility patch via reload
    Then Logger should still respond to add with dump_log keyword
