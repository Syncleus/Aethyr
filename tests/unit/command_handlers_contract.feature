Feature: CommandHandler contract compliance
  In order to ensure all textual commands remain consistent and robust
  As a maintainer of the Aethyr engine
  I want every concrete CommandHandler to respect the core CommandHandler contract.

  Background:
    Given an isolated CommandHandler test harness

  Scenario Outline: <identifier> implements the CommandHandler contract
    When the handler for "<identifier>" is instantiated
    Then the handler should inherit from CommandHandler
    And the handler should advertise help capability
    And the command handler should expose at least one command alias
    And the handler should subscribe itself on object_added
    And processing a sample command should not raise an exception

    Examples:
      | identifier |
      | look |
      | write |
      | wield |
      | who |
      | whisper |
      | whereis |
      | wear |
      | unwield |
      | time |
      | tell |
      | taste |
      | status |
      | stand |
      | smell |
      | slash |
      | skills |
      | sit |
      | set |
      | say |
      | satiety |
      | remove |
      | quit |
      | put |
      | punch |
      | pose |
      | portal |
      | open |
      | news |
      | move |
      | more |
      | map |
      | locking |
      | listen |
      | kick |
      | issue |
      | inventory |
      | health |
      | give |
      | get |
      | gait |
      | fill |
      | feel |
      | drop |
      | dodge |
      | deleteme |
      | date |
      | block |
      | close |
      | help |
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

  Scenario: HandlerRegistry registers handlers uniquely and subscribes a manager
    Given the HandlerRegistry is cleared
    And a dummy command handler class exists
    When I register the dummy handler
    And I register the dummy handler again
    Then the handler registry should contain exactly 1 handler
    When the handler registry handles a stub manager
    Then the stub manager should have exactly 1 subscription for the dummy handler

  Scenario: Registering a nil handler raises an error
    Given the HandlerRegistry is cleared
    When I attempt to register a nil handler
    Then a RuntimeError should be raised with message "Bad handler!"
