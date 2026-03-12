Feature: Expires trait
  The Expires module is mixed into game objects so they are automatically
  deleted after a specified time.

  Scenario: Expirable object can be created
    Given I have an expirable test object
    Then the expirable object should exist
    And the expirable object info should be present

  Scenario: Setting an expiration time via expire_in
    Given I have an expirable test object
    When I set the expirable object to expire in 300 seconds
    Then the expirable expiration time should be approximately 300 seconds from now

  Scenario: Running an expirable object with no expiration set
    Given I have an expirable test object
    When I run the expirable object
    Then the expirable object should not raise

  Scenario: Running an expirable object that has not yet expired
    Given I have an expirable test object
    And I set the expirable object to expire in 9999 seconds
    When I run the expirable object
    Then the expirable object should not raise

  Scenario: Running an expirable object whose time has passed
    Given I have an expirable test object
    And the expirable object has a past expiration time
    When I run the expired object expecting failure
    Then the expirable expire error should be raised
