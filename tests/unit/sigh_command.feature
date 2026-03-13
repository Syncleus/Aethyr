Feature: SighCommand action
  As a developer of the Aethyr engine
  I want SighCommand#action to produce the correct emote messages
  So that players can sigh with no target, at themselves, or at others.

  Background:
    Given a stubbed emote commands environment

  Scenario: Sigh with no target
    When the SighCommand action is invoked with no target
    Then the emcmd player should see "You exhale, sighing deeply."
    And the emcmd room should have received an event
    And the emcmd event to_other should be "TestPlayer breathes out a deep sigh."

  Scenario: Sigh targeting self
    When the SighCommand action is invoked targeting self
    Then the emcmd player should see "You sigh at your misfortunes."
    And the emcmd room should have received an event
    And the emcmd event to_other should be "TestPlayer sighs at his own misfortunes."

  Scenario: Sigh targeting another
    Given an emcmd target named "Bob" exists in the room
    When the SighCommand action is invoked targeting "Bob"
    Then the emcmd player should see "You sigh in Bob's general direction."
    And the emcmd room should have received an event
    And the emcmd event to_target should be "TestPlayer heaves a sigh in your direction."
    And the emcmd event to_other should be "TestPlayer sighs heavily in Bob's direction."
