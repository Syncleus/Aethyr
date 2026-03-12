Feature: MUD Client Compression Protocol (MCCP)

  In order to reduce bandwidth between the MUD server and clients
  As a developer of the Aethyr engine
  I want the MCCP class to compress and decompress strings via zlib
  So that network traffic can be transparently minimised

  Scenario: MCCP instance initialises with start step
    Given I require the MCCP library
    When I create a new MCCP instance
    Then the MCCP instance step should be "start"

  Scenario: MCCP step method accepts a string
    Given I require the MCCP library
    And I create a new MCCP instance
    When I call MCCP step with "IAC DO COMPRESS2"
    Then the MCCP step call should return without error

  Scenario: MCCP compresses a string
    Given I require the MCCP library
    When I compress the string "Hello, Aethyr MUD world!" using MCCP
    Then the MCCP compressed result should be a non-empty binary string
    And the MCCP compressed result should differ from "Hello, Aethyr MUD world!"

  Scenario: MCCP decompresses a previously compressed string
    Given I require the MCCP library
    When I compress the string "Round trip test payload" using MCCP
    And I decompress the MCCP compressed result
    Then the MCCP decompressed result should equal "Round trip test payload"

  Scenario: MCCP round-trips arbitrary text through compress and decompress
    Given I require the MCCP library
    When I compress the string "The quick brown fox jumps over the lazy dog" using MCCP
    And I decompress the MCCP compressed result
    Then the MCCP decompressed result should equal "The quick brown fox jumps over the lazy dog"
