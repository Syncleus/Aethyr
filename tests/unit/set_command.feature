Feature: SetCommand action
  In order to allow players to configure personal settings
  As a maintainer of the Aethyr engine
  I want SetCommand#action to correctly handle all setting types and values.

  Background:
    Given a stubbed SetCommand environment

  # --- wordwrap: nil value, word_wrap currently off (lines 15-22, 27-29) ------
  Scenario: Wordwrap with no value and word_wrap currently off
    Given the set player has word_wrap set to nil
    And the set setting is "wordwrap"
    And the set value is nil
    When the SetCommand action is invoked
    Then the set player should see "Word wrap is currently off."
    And the set player should see "Please specify 'off' or a value between 10 - 200."

  # --- wordwrap: nil value, word_wrap currently set (lines 24, 27-29) ---------
  Scenario: Wordwrap with no value and word_wrap currently set
    Given the set player has word_wrap set to 80
    And the set setting is "wordwrap"
    And the set value is nil
    When the SetCommand action is invoked
    Then the set player should see "Word wrap currently set to 80."
    And the set player should see "Please specify 'off' or a value between 10 - 200."

  # --- wordwrap: value "off" (lines 20-22, 30-33) ----------------------------
  Scenario: Wordwrap set to off disables word wrap
    Given the set player has word_wrap set to nil
    And the set setting is "wordwrap"
    And the set value is "off"
    When the SetCommand action is invoked
    Then the set player should see "Word wrap is currently off."
    And the set player should see "Word wrap is now disabled."

  # --- wordwrap: value "off" with word_wrap previously set (lines 24, 30-33) --
  Scenario: Wordwrap set to off when previously set
    Given the set player has word_wrap set to 60
    And the set setting is "wordwrap"
    And the set value is "off"
    When the SetCommand action is invoked
    Then the set player should see "Word wrap currently set to 60."
    And the set player should see "Word wrap is now disabled."

  # --- wordwrap: invalid numeric value too high (lines 35-38) -----------------
  Scenario: Wordwrap with value above 200 gives error
    Given the set player has word_wrap set to nil
    And the set setting is "wordwrap"
    And the set value is "201"
    When the SetCommand action is invoked
    Then the set player should see "Please use a value between 10 - 200."

  # --- wordwrap: invalid numeric value too low (lines 35-38) ------------------
  Scenario: Wordwrap with value below 10 gives error
    Given the set player has word_wrap set to nil
    And the set setting is "wordwrap"
    And the set value is "5"
    When the SetCommand action is invoked
    Then the set player should see "Please use a value between 10 - 200."

  # --- wordwrap: valid numeric value (lines 40-42) ----------------------------
  Scenario: Wordwrap with valid numeric value sets word wrap
    Given the set player has word_wrap set to nil
    And the set setting is "wordwrap"
    And the set value is "80"
    When the SetCommand action is invoked
    Then the set player should see "Word wrap is now set to: 80 characters."

  # --- pagelength: nil value, page_height currently off (lines 46-48, 53-55) --
  Scenario: Pagelength with no value and page_height currently off
    Given the set player has page_height set to nil
    And the set setting is "pagelength"
    And the set value is nil
    When the SetCommand action is invoked
    Then the set player should see "Pagination is currently off."
    And the set player should see "Please specify 'off' or a value between 1 - 200."

  # --- pagelength: nil value, page_height currently set (lines 50, 53-55) -----
  Scenario: Pagelength with no value and page_height currently set
    Given the set player has page_height set to 40
    And the set setting is "pagelength"
    And the set value is nil
    When the SetCommand action is invoked
    Then the set player should see "Page length is currently set to 40."
    And the set player should see "Please specify 'off' or a value between 1 - 200."

  # --- page_length alias (line 45) -------------------------------------------
  Scenario: page_length alias works the same as pagelength
    Given the set player has page_height set to nil
    And the set setting is "page_length"
    And the set value is nil
    When the SetCommand action is invoked
    Then the set player should see "Pagination is currently off."

  # --- pagelength: value "off" (lines 56-59) ----------------------------------
  Scenario: Pagelength set to off disables pagination
    Given the set player has page_height set to nil
    And the set setting is "pagelength"
    And the set value is "off"
    When the SetCommand action is invoked
    Then the set player should see "Output will no longer be paginated."

  # --- pagelength: value "off" with page_height previously set (lines 50, 56-59)
  Scenario: Pagelength set to off when previously set
    Given the set player has page_height set to 25
    And the set setting is "pagelength"
    And the set value is "off"
    When the SetCommand action is invoked
    Then the set player should see "Page length is currently set to 25."
    And the set player should see "Output will no longer be paginated."

  # --- pagelength: invalid numeric value too high (lines 61-64) ---------------
  Scenario: Pagelength with value above 200 gives error
    Given the set player has page_height set to nil
    And the set setting is "pagelength"
    And the set value is "201"
    When the SetCommand action is invoked
    Then the set player should see "Please use a value between 1 - 200."

  # --- pagelength: invalid numeric value too low (lines 61-64) ----------------
  Scenario: Pagelength with value below 1 gives error
    Given the set player has page_height set to nil
    And the set setting is "pagelength"
    And the set value is "0"
    When the SetCommand action is invoked
    Then the set player should see "Please use a value between 1 - 200."

  # --- pagelength: valid numeric value (lines 66-68) --------------------------
  Scenario: Pagelength with valid numeric value sets page height
    Given the set player has page_height set to nil
    And the set setting is "pagelength"
    And the set value is "50"
    When the SetCommand action is invoked
    Then the set player should see "Page length is now set to: 50 lines."

  # --- description (lines 72-78) - editor callback with data -----------------
  Scenario: Setting description invokes editor and sets long_desc
    Given the set setting is "desc"
    When the SetCommand action is invoked
    Then the set player should see "Set description to:"

  # --- description alias (lines 72-78) ---------------------------------------
  Scenario: Setting description with "description" alias
    Given the set setting is "description"
    When the SetCommand action is invoked
    Then the set player should see "Set description to:"

  # --- layout: basic (lines 80-83) -------------------------------------------
  Scenario: Setting layout to basic
    Given the set setting is "layout"
    And the set value is "basic"
    When the SetCommand action is invoked
    Then the set player layout should be :basic

  # --- layout: partial (lines 80, 84-85) -------------------------------------
  Scenario: Setting layout to partial
    Given the set setting is "layout"
    And the set value is "partial"
    When the SetCommand action is invoked
    Then the set player layout should be :partial

  # --- layout: full (lines 80, 86-87) ----------------------------------------
  Scenario: Setting layout to full
    Given the set setting is "layout"
    And the set value is "full"
    When the SetCommand action is invoked
    Then the set player layout should be :full

  # --- layout: wide (lines 80, 88-89) ----------------------------------------
  Scenario: Setting layout to wide
    Given the set setting is "layout"
    And the set value is "wide"
    When the SetCommand action is invoked
    Then the set player layout should be :wide

  # --- layout: invalid (lines 80, 90-91) -------------------------------------
  Scenario: Setting layout to invalid value gives error
    Given the set setting is "layout"
    And the set value is "mega"
    When the SetCommand action is invoked
    Then the set player should see "is not a valid layout"

  # --- unknown setting (line 94) ----------------------------------------------
  Scenario: Unknown setting gives error
    Given the set setting is "unknownsetting"
    And the set value is "something"
    When the SetCommand action is invoked
    Then the set player should see "No such setting: unknownsetting"

  # --- description with nil data callback (lines 73-75) -----------------------
  Scenario: Setting description with nil data does not change long_desc
    Given the set setting is "desc"
    And the editor will yield nil data
    When the SetCommand action is invoked
    Then the set player should see "Set description to:"
    And the set player long_desc should be "original description"
