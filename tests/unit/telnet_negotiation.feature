Feature: Telnet protocol negotiation
  As the Aethyr game engine
  I need a TelnetScanner that negotiates telnet options with clients
  So that terminal capabilities are correctly detected and configured

  Background:
    Given I require the telnet negotiation library

  # ── Construction & Preamble ────────────────────────────────────────────

  Scenario: Telnet handler initializes with default state
    When I create a telnet negotiation scanner with a mock socket
    Then the telnet negotiation scanner should exist

  Scenario: Telnet handler sends preamble to client
    When I create a telnet negotiation scanner with a mock socket
    And I send the telnet negotiation preamble
    Then the telnet negotiation mock socket should have received 6 messages

  # ── NAWS support flag ──────────────────────────────────────────────────

  Scenario: Telnet handler records NAWS as supported
    When I create a telnet negotiation scanner with a mock socket
    And I set telnet negotiation NAWS support to true
    Then the telnet negotiation NAWS flag should be true

  Scenario: Telnet handler records NAWS as unsupported
    When I create a telnet negotiation scanner with a mock socket
    And I set telnet negotiation NAWS support to false
    Then the telnet negotiation NAWS flag should be false

  # ── MSSP ───────────────────────────────────────────────────────────────

  Scenario: Telnet handler sends MSSP data without yaml file
    When I create a telnet negotiation scanner with a mock socket
    And I stub telnet negotiation globals for MSSP
    And I send telnet negotiation MSSP data
    Then the telnet negotiation display should have received raw MSSP data

  Scenario: Telnet handler sends MSSP data with yaml file present
    When I create a telnet negotiation scanner with a mock socket
    And I stub telnet negotiation globals for MSSP
    And I stub telnet negotiation MSSP yaml file with data
    And I send telnet negotiation MSSP data
    Then the telnet negotiation display should have received raw MSSP data
    And I restore telnet negotiation MSSP yaml stubs

  # ── process_iac: edge cases ────────────────────────────────────────────

  Scenario: Telnet handler returns false on EWOULDBLOCK
    When I create a telnet negotiation scanner with a mock socket
    And the telnet negotiation socket raises EWOULDBLOCK on peek
    And I call telnet negotiation process_iac
    Then the telnet negotiation result should be false

  Scenario: Telnet handler returns false on nil peek
    When I create a telnet negotiation scanner with a mock socket
    And the telnet negotiation socket returns nil on peek
    And I call telnet negotiation process_iac
    Then the telnet negotiation result should be false

  Scenario: Telnet handler returns true for non-IAC byte in none state
    When I create a telnet negotiation scanner with a mock socket
    And I queue telnet negotiation bytes "A"
    And I call telnet negotiation process_iac
    Then the telnet negotiation result should be true

  # ── IAC command dispatch ───────────────────────────────────────────────

  Scenario: Telnet handler transitions from none to IAC on IAC byte
    When I create a telnet negotiation scanner with a mock socket
    And I queue telnet negotiation raw byte IAC
    And I call telnet negotiation process_iac
    Then the telnet negotiation result should be false
    And the telnet negotiation IAC state should be "IAC"

  Scenario: Telnet handler handles doubled IAC as escape
    When I create a telnet negotiation scanner with a mock socket
    And I set telnet negotiation IAC state to "IAC"
    And I queue telnet negotiation raw byte IAC
    And I call telnet negotiation process_iac
    Then the telnet negotiation result should be true
    And the telnet negotiation IAC state should be "none"

  Scenario: Telnet handler transitions IAC to IAC_WILL
    When I create a telnet negotiation scanner with a mock socket
    And I set telnet negotiation IAC state to "IAC"
    And I queue telnet negotiation raw byte WILL
    And I call telnet negotiation process_iac
    Then the telnet negotiation IAC state should be "IAC_WILL"

  Scenario: Telnet handler transitions IAC to IAC_SB
    When I create a telnet negotiation scanner with a mock socket
    And I set telnet negotiation IAC state to "IAC"
    And I queue telnet negotiation raw byte SB
    And I call telnet negotiation process_iac
    Then the telnet negotiation IAC state should be "IAC_SB"

  Scenario: Telnet handler transitions IAC to IAC_WONT
    When I create a telnet negotiation scanner with a mock socket
    And I set telnet negotiation IAC state to "IAC"
    And I queue telnet negotiation raw byte WONT
    And I call telnet negotiation process_iac
    Then the telnet negotiation IAC state should be "IAC_WONT"

  Scenario: Telnet handler transitions IAC to IAC_DONT
    When I create a telnet negotiation scanner with a mock socket
    And I set telnet negotiation IAC state to "IAC"
    And I queue telnet negotiation raw byte DONT
    And I call telnet negotiation process_iac
    Then the telnet negotiation IAC state should be "IAC_DONT"

  Scenario: Telnet handler transitions IAC to IAC_DO
    When I create a telnet negotiation scanner with a mock socket
    And I set telnet negotiation IAC state to "IAC"
    And I queue telnet negotiation raw byte DO
    And I call telnet negotiation process_iac
    Then the telnet negotiation IAC state should be "IAC_DO"

  Scenario: Telnet handler resets state on unknown IAC command
    When I create a telnet negotiation scanner with a mock socket
    And I set telnet negotiation IAC state to "IAC"
    And I queue telnet negotiation raw byte NOP
    And I call telnet negotiation process_iac
    Then the telnet negotiation IAC state should be "none"

  # ── IAC_WILL option handling ───────────────────────────────────────────

  Scenario: Telnet handler responds DO BINARY to WILL BINARY
    When I create a telnet negotiation scanner with a mock socket
    And I set telnet negotiation IAC state to "IAC_WILL"
    And I queue telnet negotiation raw byte OPT_BINARY
    And I call telnet negotiation process_iac
    Then the telnet negotiation mock socket should have sent DO OPT_BINARY

  Scenario: Telnet handler enables NAWS on WILL NAWS
    When I create a telnet negotiation scanner with a mock socket
    And I set telnet negotiation IAC state to "IAC_WILL"
    And I queue telnet negotiation raw byte OPT_NAWS
    And I call telnet negotiation process_iac
    Then the telnet negotiation NAWS flag should be true

  Scenario: Telnet handler enables linemode on WILL LINEMODE
    When I create a telnet negotiation scanner with a mock socket
    And I set telnet negotiation IAC state to "IAC_WILL"
    And I queue telnet negotiation raw byte OPT_LINEMODE
    And I call telnet negotiation process_iac
    Then the telnet negotiation linemode flag should be true

  Scenario: Telnet handler responds DONT ECHO to WILL ECHO
    When I create a telnet negotiation scanner with a mock socket
    And I set telnet negotiation IAC state to "IAC_WILL"
    And I queue telnet negotiation raw byte OPT_ECHO
    And I call telnet negotiation process_iac
    Then the telnet negotiation mock socket should have sent DONT OPT_ECHO

  Scenario: Telnet handler responds DO SGA to WILL SGA
    When I create a telnet negotiation scanner with a mock socket
    And I set telnet negotiation IAC state to "IAC_WILL"
    And I queue telnet negotiation raw byte OPT_SGA
    And I call telnet negotiation process_iac
    Then the telnet negotiation mock socket should have sent DO OPT_SGA

  Scenario: Telnet handler responds DONT to unknown WILL option
    When I create a telnet negotiation scanner with a mock socket
    And I set telnet negotiation IAC state to "IAC_WILL"
    And I queue telnet negotiation raw byte OPT_TTYPE
    And I call telnet negotiation process_iac
    Then the telnet negotiation mock socket should have sent DONT OPT_TTYPE

  # ── IAC_WONT option handling ───────────────────────────────────────────

  Scenario: Telnet handler disables linemode on WONT LINEMODE
    When I create a telnet negotiation scanner with a mock socket
    And I set telnet negotiation IAC state to "IAC_WONT"
    And I queue telnet negotiation raw byte OPT_LINEMODE
    And I call telnet negotiation process_iac
    Then the telnet negotiation linemode flag should be false

  Scenario: Telnet handler disables NAWS on WONT NAWS
    When I create a telnet negotiation scanner with a mock socket
    And I set telnet negotiation IAC state to "IAC_WONT"
    And I queue telnet negotiation raw byte OPT_NAWS
    And I call telnet negotiation process_iac
    Then the telnet negotiation NAWS flag should be false

  Scenario: Telnet handler responds DONT to unknown WONT option
    When I create a telnet negotiation scanner with a mock socket
    And I set telnet negotiation IAC state to "IAC_WONT"
    And I queue telnet negotiation raw byte OPT_TTYPE
    And I call telnet negotiation process_iac
    Then the telnet negotiation mock socket should have sent DONT OPT_TTYPE response

  # ── IAC_DO option handling ─────────────────────────────────────────────

  Scenario: Telnet handler responds WILL BINARY to DO BINARY
    When I create a telnet negotiation scanner with a mock socket
    And I set telnet negotiation IAC state to "IAC_DO"
    And I queue telnet negotiation raw byte OPT_BINARY
    And I call telnet negotiation process_iac
    Then the telnet negotiation mock socket should have sent WILL OPT_BINARY

  Scenario: Telnet handler enables echo on DO ECHO
    When I create a telnet negotiation scanner with a mock socket
    And I set telnet negotiation IAC state to "IAC_DO"
    And I queue telnet negotiation raw byte OPT_ECHO
    And I call telnet negotiation process_iac
    Then the telnet negotiation echo flag should be true

  Scenario: Telnet handler sends MSSP on DO MSSP
    When I create a telnet negotiation scanner with a mock socket
    And I stub telnet negotiation globals for MSSP
    And I set telnet negotiation IAC state to "IAC_DO"
    And I queue telnet negotiation raw byte OPT_MSSP
    And I call telnet negotiation process_iac
    Then the telnet negotiation display should have received raw MSSP data
    And the telnet negotiation MSSP flag should be true

  Scenario: Telnet handler responds WONT to unknown DO option
    When I create a telnet negotiation scanner with a mock socket
    And I set telnet negotiation IAC state to "IAC_DO"
    And I queue telnet negotiation raw byte OPT_TTYPE
    And I call telnet negotiation process_iac
    Then the telnet negotiation mock socket should have sent WONT OPT_TTYPE

  # ── IAC_DONT option handling ───────────────────────────────────────────

  Scenario: Telnet handler disables echo on DONT ECHO
    When I create a telnet negotiation scanner with a mock socket
    And I set telnet negotiation IAC state to "IAC_DONT"
    And I queue telnet negotiation raw byte OPT_ECHO
    And I call telnet negotiation process_iac
    Then the telnet negotiation echo flag should be false

  Scenario: Telnet handler ignores DONT COMPRESS2
    When I create a telnet negotiation scanner with a mock socket
    And I set telnet negotiation IAC state to "IAC_DONT"
    And I queue telnet negotiation raw byte OPT_COMPRESS2
    And I call telnet negotiation process_iac
    Then the telnet negotiation IAC state should be "none"

  Scenario: Telnet handler disables MSSP on DONT MSSP
    When I create a telnet negotiation scanner with a mock socket
    And I set telnet negotiation IAC state to "IAC_DONT"
    And I queue telnet negotiation raw byte OPT_MSSP
    And I call telnet negotiation process_iac
    Then the telnet negotiation MSSP flag should be false

  Scenario: Telnet handler responds WONT to unknown DONT option
    When I create a telnet negotiation scanner with a mock socket
    And I set telnet negotiation IAC state to "IAC_DONT"
    And I queue telnet negotiation raw byte OPT_TTYPE
    And I call telnet negotiation process_iac
    Then the telnet negotiation mock socket should have sent WONT OPT_TTYPE response

  # ── Subnegotiation dispatch ────────────────────────────────────────────

  Scenario: Telnet handler enters NAWS subnegotiation
    When I create a telnet negotiation scanner with a mock socket
    And I set telnet negotiation IAC state to "IAC_SB"
    And I queue telnet negotiation raw byte OPT_NAWS
    And I call telnet negotiation process_iac
    Then the telnet negotiation IAC state should be "IAC_SB_NAWS"

  Scenario: Telnet handler enters unknown subnegotiation
    When I create a telnet negotiation scanner with a mock socket
    And I set telnet negotiation IAC state to "IAC_SB"
    And I queue telnet negotiation raw byte OPT_TTYPE
    And I call telnet negotiation process_iac
    Then the telnet negotiation IAC state should be "IAC_SB_SOMETHING"

  # ── Full NAWS negotiation (normal case) ────────────────────────────────

  Scenario: Telnet handler completes full NAWS 80x24 negotiation
    When I create a telnet negotiation scanner with a mock socket
    And I feed a telnet negotiation full NAWS sequence for width 80 and height 24
    Then the telnet negotiation display resolution should be 80 by 24

  Scenario: Telnet handler completes full NAWS 132x50 negotiation
    When I create a telnet negotiation scanner with a mock socket
    And I feed a telnet negotiation full NAWS sequence for width 132 and height 50
    Then the telnet negotiation display resolution should be 132 by 50

  # ── NAWS subneg: lwidth field ──────────────────────────────────────────

  Scenario: Telnet handler reads non-IAC lwidth in NAWS
    When I create a telnet negotiation scanner with a mock socket
    And I set telnet negotiation IAC state to "IAC_SB_NAWS"
    And I queue telnet negotiation byte value 0
    And I call telnet negotiation process_iac
    Then the telnet negotiation IAC state should be "IAC_SB_NAWS_LWIDTH"

  Scenario: Telnet handler detects IAC in lwidth position
    When I create a telnet negotiation scanner with a mock socket
    And I set telnet negotiation IAC state to "IAC_SB_NAWS"
    And I queue telnet negotiation raw byte IAC
    And I call telnet negotiation process_iac
    Then the telnet negotiation IAC state should be "IAC_SB_NAWS_IAC"

  Scenario: Telnet handler handles IAC escape in lwidth position
    When I create a telnet negotiation scanner with a mock socket
    And I set telnet negotiation IAC state to "IAC_SB_NAWS_IAC"
    And I queue telnet negotiation raw byte IAC
    And I call telnet negotiation process_iac
    Then the telnet negotiation IAC state should be "IAC_SB_NAWS_LWIDTH"

  Scenario: Telnet handler raises on invalid IAC escape in NAWS lwidth
    When I create a telnet negotiation scanner with a mock socket
    And I set telnet negotiation IAC state to "IAC_SB_NAWS_IAC"
    And I queue telnet negotiation byte value 99
    Then calling telnet negotiation process_iac should raise "IAC escape expected"

  # ── NAWS subneg: hwidth field ──────────────────────────────────────────

  Scenario: Telnet handler reads non-IAC hwidth in NAWS
    When I create a telnet negotiation scanner with a mock socket
    And I set telnet negotiation IAC state to "IAC_SB_NAWS_LWIDTH"
    And I queue telnet negotiation byte value 80
    And I call telnet negotiation process_iac
    Then the telnet negotiation IAC state should be "IAC_SB_NAWS_LWIDTH_HWIDTH"

  Scenario: Telnet handler detects IAC in hwidth position
    When I create a telnet negotiation scanner with a mock socket
    And I set telnet negotiation IAC state to "IAC_SB_NAWS_LWIDTH"
    And I queue telnet negotiation raw byte IAC
    And I call telnet negotiation process_iac
    Then the telnet negotiation IAC state should be "IAC_SB_NAWS_LWIDTH_IAC"

  Scenario: Telnet handler handles IAC escape in hwidth position
    When I create a telnet negotiation scanner with a mock socket
    And I set telnet negotiation IAC state to "IAC_SB_NAWS_LWIDTH_IAC"
    And I queue telnet negotiation raw byte IAC
    And I call telnet negotiation process_iac
    Then the telnet negotiation IAC state should be "IAC_SB_NAWS_LWIDTH_HWIDTH"

  Scenario: Telnet handler raises on invalid IAC escape in NAWS hwidth
    When I create a telnet negotiation scanner with a mock socket
    And I set telnet negotiation IAC state to "IAC_SB_NAWS_LWIDTH_IAC"
    And I queue telnet negotiation byte value 99
    Then calling telnet negotiation process_iac should raise "IAC escape expected"

  Scenario: Telnet handler handles IAC escape for hwidth value 255
    When I create a telnet negotiation scanner with a mock socket
    And I set telnet negotiation IAC state to "IAC_SB_NAWS_LWIDTH_HWIDTH"
    And I queue telnet negotiation raw byte IAC
    Then calling telnet negotiation process_iac should raise an error

  # ── NAWS subneg: lheight field ─────────────────────────────────────────

  Scenario: Telnet handler reads non-IAC lheight in NAWS
    When I create a telnet negotiation scanner with a mock socket
    And I set telnet negotiation IAC state to "IAC_SB_NAWS_LWIDTH_HWIDTH"
    And I queue telnet negotiation byte value 0
    And I call telnet negotiation process_iac
    Then the telnet negotiation IAC state should be "IAC_SB_NAWS_LWIDTH_HWIDTH_LHEIGHT"

  Scenario: Telnet handler raises when lheight byte is IAC
    When I create a telnet negotiation scanner with a mock socket
    And I set telnet negotiation IAC state to "IAC_SB_NAWS_LWIDTH_HWIDTH"
    And I queue telnet negotiation raw byte IAC
    Then calling telnet negotiation process_iac should raise "escaped IAC expected but not found"

  # ── NAWS subneg: hheight field ─────────────────────────────────────────

  Scenario: Telnet handler reads non-IAC hheight in NAWS
    When I create a telnet negotiation scanner with a mock socket
    And I set telnet negotiation IAC state to "IAC_SB_NAWS_LWIDTH_HWIDTH_LHEIGHT"
    And I queue telnet negotiation byte value 24
    And I call telnet negotiation process_iac
    Then the telnet negotiation IAC state should be "IAC_SB_NAWS_LWIDTH_HWIDTH_LHEIGHT_HHEIGHT"

  Scenario: Telnet handler detects IAC in hheight position
    When I create a telnet negotiation scanner with a mock socket
    And I set telnet negotiation IAC state to "IAC_SB_NAWS_LWIDTH_HWIDTH_LHEIGHT"
    And I queue telnet negotiation raw byte IAC
    And I call telnet negotiation process_iac
    Then the telnet negotiation IAC state should be "IAC_SB_NAWS_LWIDTH_HWIDTH_LHEIGHT_IAC"

  Scenario: Telnet handler handles IAC escape in hheight position
    When I create a telnet negotiation scanner with a mock socket
    And I set telnet negotiation IAC state to "IAC_SB_NAWS_LWIDTH_HWIDTH_LHEIGHT_IAC"
    And I queue telnet negotiation raw byte IAC
    And I call telnet negotiation process_iac
    Then the telnet negotiation IAC state should be "IAC_SB_NAWS_LWIDTH_HWIDTH_LHEIGHT_HHEIGHT"

  Scenario: Telnet handler raises on invalid IAC escape in NAWS hheight
    When I create a telnet negotiation scanner with a mock socket
    And I set telnet negotiation IAC state to "IAC_SB_NAWS_LWIDTH_HWIDTH_LHEIGHT_IAC"
    And I queue telnet negotiation byte value 99
    Then calling telnet negotiation process_iac should raise "IAC escape expected"

  # ── NAWS subneg: end sequence ──────────────────────────────────────────

  Scenario: Telnet handler expects IAC after hheight
    When I create a telnet negotiation scanner with a mock socket
    And I set telnet negotiation IAC state to "IAC_SB_NAWS_LWIDTH_HWIDTH_LHEIGHT_HHEIGHT"
    And I queue telnet negotiation raw byte IAC
    And I call telnet negotiation process_iac
    Then the telnet negotiation IAC state should be "IAC_SB_NAWS_LWIDTH_HWIDTH_LHEIGHT_HHEIGHT_IAC"

  Scenario: Telnet handler raises on non-IAC after hheight
    When I create a telnet negotiation scanner with a mock socket
    And I set telnet negotiation IAC state to "IAC_SB_NAWS_LWIDTH_HWIDTH_LHEIGHT_HHEIGHT"
    And I queue telnet negotiation byte value 99
    Then calling telnet negotiation process_iac should raise "invalid IAC"

  Scenario: Telnet handler completes NAWS on SE after IAC
    When I create a telnet negotiation scanner with a mock socket
    And I set telnet negotiation NAWS dimensions to lw 0 hw 80 lh 0 hh 24
    And I set telnet negotiation IAC state to "IAC_SB_NAWS_LWIDTH_HWIDTH_LHEIGHT_HHEIGHT_IAC"
    And I queue telnet negotiation raw byte SE
    And I call telnet negotiation process_iac
    Then the telnet negotiation display resolution should be 80 by 24
    And the telnet negotiation IAC state should be "none"

  Scenario: Telnet handler raises on non-SE after final IAC in NAWS
    When I create a telnet negotiation scanner with a mock socket
    And I set telnet negotiation IAC state to "IAC_SB_NAWS_LWIDTH_HWIDTH_LHEIGHT_HHEIGHT_IAC"
    And I queue telnet negotiation byte value 99
    Then calling telnet negotiation process_iac should raise "invalid IAC"

  # ── Unknown subnegotiation passthrough ─────────────────────────────────

  Scenario: Telnet handler stays in SB_SOMETHING on non-IAC data
    When I create a telnet negotiation scanner with a mock socket
    And I set telnet negotiation IAC state to "IAC_SB_SOMETHING"
    And I queue telnet negotiation byte value 65
    And I call telnet negotiation process_iac
    Then the telnet negotiation IAC state should be "IAC_SB_SOMETHING"

  Scenario: Telnet handler detects IAC inside unknown subnegotiation
    When I create a telnet negotiation scanner with a mock socket
    And I set telnet negotiation IAC state to "IAC_SB_SOMETHING"
    And I queue telnet negotiation raw byte IAC
    And I call telnet negotiation process_iac
    Then the telnet negotiation IAC state should be "IAC_SB_SOMETHING_IAC"

  Scenario: Telnet handler handles doubled IAC inside unknown subnegotiation
    When I create a telnet negotiation scanner with a mock socket
    And I set telnet negotiation IAC state to "IAC_SB_SOMETHING_IAC"
    And I queue telnet negotiation raw byte IAC
    And I call telnet negotiation process_iac
    Then the telnet negotiation IAC state should be "IAC_SB_SOMETHING"

  Scenario: Telnet handler ends unknown subnegotiation on SE
    When I create a telnet negotiation scanner with a mock socket
    And I set telnet negotiation IAC state to "IAC_SB_SOMETHING_IAC"
    And I queue telnet negotiation raw byte SE
    And I call telnet negotiation process_iac
    Then the telnet negotiation IAC state should be "none"

  # ── Fallback else branch ───────────────────────────────────────────────

  Scenario: Telnet handler resets on unrecognized IAC state
    When I create a telnet negotiation scanner with a mock socket
    And I set telnet negotiation IAC state to "BOGUS_STATE"
    And I queue telnet negotiation byte value 65
    And I call telnet negotiation process_iac
    Then the telnet negotiation IAC state should be "none"
