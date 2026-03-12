Feature: File::Tail – tail files in Ruby

  In order to watch growing logfiles in real-time
  As a developer of the Aethyr engine
  I want the File::Tail module to correctly seek, read, and follow files
  So that I can implement log-watching behaviour without external dependencies

  # ---------------------------------------------------------------------------
  #  Exception hierarchy
  # ---------------------------------------------------------------------------
  Scenario: Exception classes are defined and inherit correctly
    Given I require the Tail library
    Then TailException should be a subclass of Exception
    And DeletedException should be a subclass of TailException
    And ReturnException should be a subclass of TailException
    And BreakException should be a subclass of TailException
    And ReopenException should be a subclass of TailException

  Scenario: ReopenException stores mode defaulting to bottom
    Given I require the Tail library
    When I create a ReopenException with default mode
    Then the ReopenException mode should be "bottom"

  Scenario: ReopenException stores explicit top mode
    Given I require the Tail library
    When I create a ReopenException with mode "top"
    Then the ReopenException mode should be "top"

  # ---------------------------------------------------------------------------
  #  Attribute accessors and after_reopen callback
  # ---------------------------------------------------------------------------
  Scenario: Tail attributes can be set and read
    Given I require the Tail library
    And I have a tailable tempfile with 10 lines
    When I set tail attributes on the file
    Then the tail attributes should reflect the values I set

  Scenario: after_reopen callback can be registered
    Given I require the Tail library
    And I have a tailable tempfile with 5 lines
    When I register an after_reopen callback
    Then the after_reopen callback should be stored

  # ---------------------------------------------------------------------------
  #  forward method
  # ---------------------------------------------------------------------------
  Scenario: forward(0) positions at the start of the file
    Given I require the Tail library
    And I have a tailable tempfile with 5 lines
    When I call forward with 0
    Then the file position should be at the beginning

  Scenario: forward(n) skips the first n lines
    Given I require the Tail library
    And I have a tailable tempfile with 5 lines
    When I call forward with 3
    And I read the remaining lines
    Then I should have 2 remaining lines

  # ---------------------------------------------------------------------------
  #  backward method
  # ---------------------------------------------------------------------------
  Scenario: backward(0) seeks to the end of the file
    Given I require the Tail library
    And I have a tailable tempfile with 5 lines
    When I call backward with 0
    Then the file should be at EOF

  Scenario: backward(n) with small file (bufsiz > file size)
    Given I require the Tail library
    And I have a tailable tempfile with 5 lines
    When I call backward with 3
    And I read the remaining lines
    Then I should have 3 remaining lines

  Scenario: backward(n) with large file (bufsiz < file size)
    Given I require the Tail library
    And I have a tailable tempfile with 20 lines
    When I call backward with 5 and bufsiz 32
    And I read the remaining lines
    Then I should have 5 remaining lines

  # ---------------------------------------------------------------------------
  #  tail method
  # ---------------------------------------------------------------------------
  Scenario: tail(n) with a block yields n lines
    Given I require the Tail library
    And I have a tailable tempfile with 5 lines
    When I call tail with n=3 and a block
    Then the block should have received 3 lines

  Scenario: tail(n) without a block returns an array
    Given I require the Tail library
    And I have a tailable tempfile with 5 lines
    When I call tail with n=3 and no block
    Then tail should return an array of 3 lines

  Scenario: tail with return_if_eof returns when file ends
    Given I require the Tail library
    And I have a tailable tempfile with 3 lines
    And I configure the file with return_if_eof true
    When I call tail with no limit and a block
    Then the block should have received 3 lines

  Scenario: tail with break_if_eof raises BreakException
    Given I require the Tail library
    And I have a tailable tempfile with 3 lines
    And I configure the file with break_if_eof true
    When I call tail expecting a BreakException
    Then a BreakException should have been raised

  # ---------------------------------------------------------------------------
  #  preset_attributes (tested implicitly through tail)
  # ---------------------------------------------------------------------------
  Scenario: preset_attributes sets defaults when tail is called
    Given I require the Tail library
    And I have a tailable tempfile with 2 lines
    And I configure the file with return_if_eof true
    When I call tail with no limit and a block
    Then the preset attributes should have been initialised

  # ---------------------------------------------------------------------------
  #  restat – detecting inode/device changes and file truncation
  # ---------------------------------------------------------------------------
  Scenario: restat raises ReopenException when inode changes
    Given I require the Tail library
    And I have a tailable tempfile with 3 lines
    And I configure the file with return_if_eof true
    When I simulate an inode change and call tail
    Then a ReopenException should have been raised during restat

  Scenario: restat raises ReopenException when file shrinks
    Given I require the Tail library
    And I have a tailable tempfile with 3 lines
    And I configure the file with return_if_eof true
    When I simulate a file size shrink and call tail
    Then a ReopenException should have been raised during restat

  Scenario: restat raises ReopenException on ENOENT
    Given I require the Tail library
    And I have a tailable tempfile with 3 lines
    And I configure the file with return_if_eof true
    When I simulate ENOENT in restat and call tail
    Then a ReopenException should have been raised during restat

  # ---------------------------------------------------------------------------
  #  sleep_interval – backoff behaviour
  # ---------------------------------------------------------------------------
  Scenario: sleep_interval with lines read estimates interval
    Given I require the Tail library
    And I have a tailable tempfile with 3 lines
    When I exercise sleep_interval with lines greater than zero
    Then the interval should have been adjusted downward

  Scenario: sleep_interval with no lines uses exponential backoff
    Given I require the Tail library
    And I have a tailable tempfile with 3 lines
    When I exercise sleep_interval with zero lines
    Then the interval should have been doubled

  Scenario: sleep_interval caps at max_interval
    Given I require the Tail library
    And I have a tailable tempfile with 3 lines
    When I exercise sleep_interval beyond max_interval
    Then the interval should equal max_interval

  # ---------------------------------------------------------------------------
  #  reopen_file
  # ---------------------------------------------------------------------------
  Scenario: reopen_file with bottom mode calls backward
    Given I require the Tail library
    And I have a tailable tempfile with 5 lines
    When I call reopen_file with mode bottom
    Then the file should be at EOF

  Scenario: reopen_file with top mode does not call backward
    Given I require the Tail library
    And I have a tailable tempfile with 5 lines
    When I call reopen_file with mode top
    Then the file should be at the beginning

  Scenario: reopen_file raises DeletedException when file missing and reopen_deleted is false
    Given I require the Tail library
    And I have a tailable tempfile with 3 lines
    When I delete the file and call reopen_file with reopen_deleted false
    Then a DeletedException should have been raised

  # ---------------------------------------------------------------------------
  #  read_line – ENOENT/ESTALE triggers ReopenException
  # ---------------------------------------------------------------------------
  Scenario: read_line with ENOENT raises ReopenException
    Given I require the Tail library
    And I have a tailable tempfile with 3 lines
    When I simulate ENOENT during readline
    Then a ReopenException should have been raised from read_line

  Scenario: read_line without n reads single lines
    Given I require the Tail library
    And I have a tailable tempfile with 3 lines
    And I configure the file with return_if_eof true
    When I call tail with no n to exercise unlimited read_line
    Then the block should have received 3 lines

  # ---------------------------------------------------------------------------
  #  reopen_suspicious triggers ReopenException from read_line
  # ---------------------------------------------------------------------------
  Scenario: reopen_suspicious triggers ReopenException after suspicious_interval
    Given I require the Tail library
    And I have a tailable tempfile with 2 lines
    When I simulate suspicious silence and call tail
    Then tail should have attempted a reopen

  # ---------------------------------------------------------------------------
  #  debug method (no-op)
  # ---------------------------------------------------------------------------
  Scenario: debug method executes without error
    Given I require the Tail library
    And I have a tailable tempfile with 2 lines
    And I configure the file with return_if_eof true
    When I call tail with n=2 and a block
    Then the block should have received 2 lines

  # ---------------------------------------------------------------------------
  #  Logfile.open – various option combinations
  # ---------------------------------------------------------------------------
  Scenario: Logfile.open with block and backward option
    Given I require the Tail library
    And I have a plain tempfile with 10 lines
    When I call Logfile.open with backward 3 and a block
    Then the Logfile block should have received the file
    And the file should be closed

  Scenario: Logfile.open without block returns file
    Given I require the Tail library
    And I have a plain tempfile with 10 lines
    When I call Logfile.open without a block
    Then Logfile.open should return an open file
    And I close the returned file

  Scenario: Logfile.open with forward option
    Given I require the Tail library
    And I have a plain tempfile with 10 lines
    When I call Logfile.open with forward 3 and a block
    Then the Logfile block should have received the file

  Scenario: Logfile.open with after_reopen option
    Given I require the Tail library
    And I have a plain tempfile with 5 lines
    When I call Logfile.open with after_reopen and a block
    Then the Logfile block should have received the file

  Scenario: Logfile.open with attribute options
    Given I require the Tail library
    And I have a plain tempfile with 5 lines
    When I call Logfile.open with interval and max_interval options
    Then the Logfile block should have received the file with correct attributes

  # ---------------------------------------------------------------------------
  #  Logfile.tail
  # ---------------------------------------------------------------------------
  Scenario: Logfile.tail yields lines from the file
    Given I require the Tail library
    And I have a plain tempfile with 5 lines
    When I call Logfile.tail with return_if_eof
    Then Logfile.tail should have yielded all 5 lines

  # ---------------------------------------------------------------------------
  #  Main script block ($0 == __FILE__)
  # ---------------------------------------------------------------------------
  Scenario: Main script block runs with a filename and positive number
    Given I require the Tail library
    And I have a plain tempfile with 5 lines
    When I execute the main script block with the tempfile and number 3
    Then the main block should have executed without error

  Scenario: Main script block runs with a negative number (forward)
    Given I require the Tail library
    And I have a plain tempfile with 5 lines
    When I execute the main script block with the tempfile and number -2
    Then the main block should have executed without error

  Scenario: Main script block fails without a filename
    Given I require the Tail library
    When I execute the main script block without a filename
    Then the main block should have raised a usage error

  # ---------------------------------------------------------------------------
  #  Additional coverage: deprecated :wind/:rewind options
  # ---------------------------------------------------------------------------
  Scenario: Logfile.open with deprecated :rewind option
    Given I require the Tail library
    And I have a plain tempfile with 5 lines
    When I call Logfile.open with deprecated rewind option
    Then the Logfile block should have received the file

  # ---------------------------------------------------------------------------
  #  Additional coverage: Logfile.tail default backward
  # ---------------------------------------------------------------------------
  Scenario: Logfile.tail defaults backward to 0 when no forward/backward given
    Given I require the Tail library
    And I have a plain tempfile with 3 lines
    When I call Logfile.tail with only return_if_eof
    Then Logfile.tail should have yielded all 0 lines

  # ---------------------------------------------------------------------------
  #  Additional coverage: backward EINVAL retry
  # ---------------------------------------------------------------------------
  Scenario: backward handles EINVAL by retrying with smaller size
    Given I require the Tail library
    And I have a tailable tempfile with 5 lines
    When I call backward that triggers EINVAL retry
    And I read the remaining lines
    Then I should have at least 1 remaining lines

  # ---------------------------------------------------------------------------
  #  Additional coverage: tail ReopenException handling (drain + reopen + callback)
  # ---------------------------------------------------------------------------
  Scenario: tail handles ReopenException by draining and reopening
    Given I require the Tail library
    And I have a tailable tempfile with 5 lines
    When I trigger a ReopenException during tail with after_reopen callback
    Then the after_reopen callback should have been invoked
    And tail should have collected some lines

  # ---------------------------------------------------------------------------
  #  Additional coverage: sleep_interval called from read_line on EOF
  # ---------------------------------------------------------------------------
  Scenario: read_line calls sleep_interval when neither break nor return is set
    Given I require the Tail library
    And I have a tailable tempfile with 2 lines
    When I call tail with sleep_interval fallback
    Then tail should eventually return with collected lines

  # ---------------------------------------------------------------------------
  #  Additional coverage: reopen_file with reopen_deleted true retries
  # ---------------------------------------------------------------------------
  Scenario: reopen_file retries when file is deleted and reopen_deleted is true
    Given I require the Tail library
    And I have a tailable tempfile with 3 lines
    When I call reopen_file with deleted file and reopen_deleted true
    Then the file should have been reopened successfully

  # ---------------------------------------------------------------------------
  #  Additional coverage: $0 == __FILE__ main block via load
  # ---------------------------------------------------------------------------
  Scenario: Loading tail.rb as main script executes the main block
    Given I require the Tail library
    And I have a plain tempfile with 5 lines
    When I load tail.rb as the main script with the tempfile
    Then the main block should have executed without error
