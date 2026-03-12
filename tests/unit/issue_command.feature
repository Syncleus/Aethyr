Feature: IssueCommand action
  In order to let players submit and manage issues (bugs, ideas, typos)
  As a developer of the Aethyr engine
  I want the IssueCommand to correctly dispatch issue operations.

  Background:
    Given a stubbed IssueCommand environment

  # ── option "new" (lines 14, 16-17) ─────────────────────────────────────────

  Scenario: Submitting a new issue
    When the issue command is invoked with option "new" itype "bug" and value "Broken door"
    Then the issue player should see "Thank you for submitting bug"

  # ── option "add" without issue_id (lines 19-20) ────────────────────────────

  Scenario: Adding to an issue without specifying issue_id
    When the issue command is invoked with option "add" itype "bug" and no issue_id
    Then the issue player should see "Please specify a bug number."

  # ── option "add" with access denied (lines 22-24) ──────────────────────────

  Scenario: Adding to an issue with access denied
    Given issue access will be denied with "You cannot access that bug."
    When the issue command is invoked with option "add" itype "bug" issue_id "1" and value "extra info"
    Then the issue player should see "You cannot access that bug."

  # ── option "add" with access granted (lines 22, 26) ────────────────────────

  Scenario: Adding to an issue with access granted
    Given issue access will be granted
    When the issue command is invoked with option "add" itype "bug" issue_id "1" and value "extra info"
    Then the issue player should see "Added your comment"

  # ── option "del" without issue_id (lines 30-31) ────────────────────────────

  Scenario: Deleting an issue without specifying issue_id
    When the issue command is invoked with option "del" itype "bug" and no issue_id
    Then the issue player should see "Please specify a bug number."

  # ── option "del" with access denied (lines 33-35) ──────────────────────────

  Scenario: Deleting an issue with access denied
    Given issue access will be denied with "You cannot access that bug."
    When the issue command is invoked with option "del" itype "bug" issue_id "1" and value ""
    Then the issue player should see "You cannot access that bug."

  # ── option "del" with access granted (lines 33, 37) ────────────────────────

  Scenario: Deleting an issue with access granted
    Given issue access will be granted
    When the issue command is invoked with option "del" itype "bug" issue_id "1" and value ""
    Then the issue player should see "Deleted bug"

  # ── option "list" as admin with results (lines 41-42, 49) ──────────────────

  Scenario: Listing issues as admin with results
    Given the issue player is admin
    When the issue command is invoked with option "list" itype "bug" and no issue_id
    Then the issue player should see "bug#"

  # ── option "list" as non-admin with results (lines 44, 49) ─────────────────

  Scenario: Listing issues as non-admin with results
    When the issue command is invoked with option "list" itype "bug" and no issue_id
    Then the issue player should see "bug#"

  # ── option "list" with empty list (lines 46-47) ────────────────────────────

  Scenario: Listing issues when none exist
    Given the issue list is empty
    When the issue command is invoked with option "list" itype "idea" and no issue_id
    Then the issue player should see "No ideas to list."

  # ── option "show" without issue_id (lines 52-53) ───────────────────────────

  Scenario: Showing an issue without specifying issue_id
    When the issue command is invoked with option "show" itype "bug" and no issue_id
    Then the issue player should see "Please specify a bug number."

  # ── option "show" with access denied (lines 55-57) ─────────────────────────

  Scenario: Showing an issue with access denied
    Given issue access will be denied with "You cannot access that bug."
    When the issue command is invoked with option "show" itype "bug" issue_id "1" and value ""
    Then the issue player should see "You cannot access that bug."

  # ── option "show" with access granted (lines 55, 59) ───────────────────────

  Scenario: Showing an issue with access granted
    Given issue access will be granted
    When the issue command is invoked with option "show" itype "bug" issue_id "1" and value ""
    Then the issue player should see "Reported by"

  # ── option "status" as non-admin (lines 63-64) ─────────────────────────────

  Scenario: Changing status as non-admin is denied
    When the issue command is invoked with option "status" itype "bug" issue_id "1" and value "resolved"
    Then the issue player should see "Only administrators may change a bug's status."

  # ── option "status" as admin without issue_id (lines 65-66) ────────────────

  Scenario: Changing status as admin without issue_id
    Given the issue player is admin
    When the issue command is invoked with option "status" itype "bug" and no issue_id
    Then the issue player should see "Please specify a bug number."

  # ── option "status" as admin with issue_id (line 68) ───────────────────────

  Scenario: Changing status as admin with issue_id
    Given the issue player is admin
    When the issue command is invoked with option "status" itype "bug" issue_id "1" and value "resolved"
    Then the issue player should see "Set status of bug"
