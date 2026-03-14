Feature: TextUtil wrap method
  In order to render text correctly within fixed-width terminal displays
  As a developer of the Aethyr engine
  I want the wrap method to handle word-wrapping, ANSI escapes, and newlines.

  Background:
    Given a TextUtil wrapper instance

  # ── Short message (under width) ──────────────────────────────────────────

  Scenario: Short message returns a single-element array
    When I wrap the text_util message "Hello world" at width 80
    Then the text_util result should have 1 line
    And text_util line 0 should be "Hello world"

  # ── Normal word-boundary wrapping ────────────────────────────────────────

  Scenario: Long message wraps at word boundaries
    When I wrap the text_util message "aaa bbb ccc ddd" at width 8
    Then the text_util result should have 2 lines
    And text_util line 0 should be "aaa bbb "
    And text_util line 1 should be "ccc ddd"

  # ── ANSI escape code handling ────────────────────────────────────────────

  Scenario: ANSI escape codes are preserved but not counted toward width
    When I wrap a text_util message with ANSI codes and width 10
    Then the text_util result should contain the ANSI escape sequence
    And the ANSI text_util wrap should not split mid-escape

  # ── \r\n newline handling ────────────────────────────────────────────────

  Scenario: Message with CRLF newlines splits at the newline
    When I wrap the text_util message with CRLF newlines at width 10
    Then the text_util result should have 2 lines
    And text_util line 0 should be "hello"
    And text_util line 1 should be "world"

  # ── \n\r newline handling ────────────────────────────────────────────────

  Scenario: Message with NLCR newlines splits at the newline
    When I wrap the text_util message with NLCR newlines at width 10
    Then the text_util result should have 2 lines
    And text_util line 0 should be "hello"
    And text_util line 1 should be "world"

  # ── Lone \r handling ─────────────────────────────────────────────────────

  Scenario: Message with lone carriage return splits at the return
    When I wrap the text_util message with a lone CR at width 10
    Then the text_util result should have 2 lines
    And text_util line 0 should be "hello"
    And text_util line 1 should be "world"

  # ── Lone \n handling ─────────────────────────────────────────────────────

  Scenario: Message with lone newline splits at the newline
    When I wrap the text_util message with a lone LF at width 10
    Then the text_util result should have 2 lines
    And text_util line 0 should be "hello"
    And text_util line 1 should be "world"

  # ── Long word exceeding width (buffer_count == width) ────────────────────

  Scenario: A word longer than width is force-split at the width boundary
    When I wrap a text_util message with a 10-char word at width 5
    Then the text_util result should have 3 lines
    And text_util line 0 should be "abcde"
    And text_util line 1 should be "fghij"

  # ── Line overflow with existing line content ─────────────────────────────

  Scenario: Buffer overflows width and existing line is flushed first
    When I wrap the text_util message "abc defghijkl" at width 10
    Then text_util line 0 should be "abc "
    And text_util line 1 should be "defghijkl"
