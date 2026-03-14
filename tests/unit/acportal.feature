Feature: AcportalCommand action
  In order to let admins create portal objects with optional custom actions
  As a maintainer of the Aethyr engine
  I want AcportalCommand#action to create a portal and optionally set a custom portal_action.

  Background:
    Given a stubbed AcportalCommand environment

  # Lines 15-17: action body executes, portal_action is nil so the if-branch is skipped
  Scenario: Creating a portal with no portal_action set
    Given no acportal portal_action is provided
    When the AcportalCommand action is invoked
    Then Admin.acreate should have been called for acportal
    And the acportal object portal_action should not have been changed

  # Lines 15-19: action body executes, portal_action is "enter" so the if-branch is skipped
  Scenario: Creating a portal with portal_action set to enter
    Given the acportal portal_action is "enter"
    When the AcportalCommand action is invoked
    Then Admin.acreate should have been called for acportal
    And the acportal object portal_action should not have been changed

  # Lines 15-19: action body executes, portal_action is "push" so the if-branch runs
  Scenario: Creating a portal with a custom portal_action
    Given the acportal portal_action is "push"
    When the AcportalCommand action is invoked
    Then Admin.acreate should have been called for acportal
    And the acportal object portal_action should be :push

  # Lines 15-19: action body with uppercase portal_action triggers downcase + to_sym
  Scenario: Creating a portal with an uppercase custom portal_action
    Given the acportal portal_action is "PULL"
    When the AcportalCommand action is invoked
    Then Admin.acreate should have been called for acportal
    And the acportal object portal_action should be :pull
