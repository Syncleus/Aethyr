Feature: AdminHandler contract compliance
  In order to ensure all admin textual commands remain consistent and secure
  As a maintainer of the Aethyr engine
  I want every concrete AdminHandler to respect the core AdminHandler contract.

  Background:
    Given an isolated AdminHandler test harness

  Scenario Outline: <identifier> implements the AdminHandler contract
    Given the admin handler "<identifier>" class is resolved
    And the admin handler is instantiated
    Then the handler should inherit from AdminHandler
    And the handler should provide help capability
    And the handler should expose at least one command alias
    And object_added should subscribe the handler for admin player
    And object_added should not subscribe the handler for regular player
    And player_input should not raise

    Examples:
      | identifier |
      | acarea |
      | terrain |
      | restart |
      | deleteplayer |
      | awho |
      | awatch |
      | ateach |
      | astatus |
      | ashow |
      | aset |
      | asave |
      | areload |
      | areas |
      | areact |
      | aput |
      | alook |
      | alog |
      | alist |
      | alearn |
      | ainfo |
      | ahide |
      | ahelp |
      | aforce |
      | adesc |
      | adelete |
      | acroom |
      | acreate |
      | acprop |
      | acportal |
      | aconfig |
      | acomment |
      | acomm |
      | acexit |
      | acdoor | 