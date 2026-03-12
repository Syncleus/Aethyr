Feature: Telnet protocol constants
  The telnet_codes module defines standard Telnet protocol command bytes
  and option codes used by the MUD connection layer.

  Scenario: Loading telnet codes defines all command constants
    Given I require the telnet codes library
    Then the telnet codes IAC constant should equal byte 255
    And the telnet codes DONT constant should equal byte 254
    And the telnet codes DO constant should equal byte 253
    And the telnet codes WONT constant should equal byte 252
    And the telnet codes WILL constant should equal byte 251
    And the telnet codes SB constant should equal byte 250
    And the telnet codes GA constant should equal byte 249
    And the telnet codes EL constant should equal byte 248
    And the telnet codes EC constant should equal byte 247
    And the telnet codes AYT constant should equal byte 246
    And the telnet codes AO constant should equal byte 245
    And the telnet codes IP constant should equal byte 244
    And the telnet codes BREAK constant should equal byte 243
    And the telnet codes DM constant should equal byte 242
    And the telnet codes NOP constant should equal byte 241
    And the telnet codes SE constant should equal byte 240
    And the telnet codes EOR constant should equal byte 239
    And the telnet codes ABORT constant should equal byte 238
    And the telnet codes SUSP constant should equal byte 237
    And the telnet codes EOF constant should equal byte 236
    And the telnet codes SYNCH constant should equal byte 242

  Scenario: Loading telnet codes defines standard option constants
    Given I require the telnet codes library
    Then the Telnet protocol constant OPT_BINARY should equal byte 0
    And the Telnet protocol constant OPT_ECHO should equal byte 1
    And the Telnet protocol constant OPT_RCP should equal byte 2
    And the Telnet protocol constant OPT_SGA should equal byte 3
    And the Telnet protocol constant OPT_NAMS should equal byte 4
    And the Telnet protocol constant OPT_STATUS should equal byte 5
    And the Telnet protocol constant OPT_TM should equal byte 6
    And the Telnet protocol constant OPT_RCTE should equal byte 7
    And the Telnet protocol constant OPT_NAOL should equal byte 8
    And the Telnet protocol constant OPT_NAOP should equal byte 9
    And the Telnet protocol constant OPT_NAOCRD should equal byte 10
    And the Telnet protocol constant OPT_NAOHTS should equal byte 11
    And the Telnet protocol constant OPT_NAOHTD should equal byte 12
    And the Telnet protocol constant OPT_NAOFFD should equal byte 13
    And the Telnet protocol constant OPT_NAOVTS should equal byte 14
    And the Telnet protocol constant OPT_NAOVTD should equal byte 15
    And the Telnet protocol constant OPT_NAOLFD should equal byte 16
    And the Telnet protocol constant OPT_XASCII should equal byte 17
    And the Telnet protocol constant OPT_LOGOUT should equal byte 18
    And the Telnet protocol constant OPT_BM should equal byte 19
    And the Telnet protocol constant OPT_DET should equal byte 20
    And the Telnet protocol constant OPT_SUPDUP should equal byte 21
    And the Telnet protocol constant OPT_SUPDUPOUTPUT should equal byte 22
    And the Telnet protocol constant OPT_SNDLOC should equal byte 23
    And the Telnet protocol constant OPT_TTYPE should equal byte 24
    And the Telnet protocol constant OPT_EOR should equal byte 25
    And the Telnet protocol constant OPT_TUID should equal byte 26
    And the Telnet protocol constant OPT_OUTMRK should equal byte 27
    And the Telnet protocol constant OPT_TTYLOC should equal byte 28
    And the Telnet protocol constant OPT_3270REGIME should equal byte 29
    And the Telnet protocol constant OPT_X3PAD should equal byte 30
    And the Telnet protocol constant OPT_NAWS should equal byte 31
    And the Telnet protocol constant OPT_TSPEED should equal byte 32
    And the Telnet protocol constant OPT_LFLOW should equal byte 33
    And the Telnet protocol constant OPT_LINEMODE should equal byte 34
    And the Telnet protocol constant OPT_XDISPLOC should equal byte 35
    And the Telnet protocol constant OPT_OLD_ENVIRON should equal byte 36
    And the Telnet protocol constant OPT_AUTHENTICATION should equal byte 37
    And the Telnet protocol constant OPT_ENCRYPT should equal byte 38
    And the Telnet protocol constant OPT_NEW_ENVIRON should equal byte 39
    And the Telnet protocol constant OPT_EXOPL should equal byte 255

  Scenario: Loading telnet codes defines MCCP and MSSP constants
    Given I require the telnet codes library
    Then the Telnet protocol constant OPT_COMPRESS should equal byte 85
    And the Telnet protocol constant OPT_COMPRESS2 should equal byte 86
    And the Telnet protocol constant OPT_MSSP should equal byte 70
    And the Telnet protocol constant MSSP_VAR should equal byte 1
    And the Telnet protocol constant MSSP_VAL should equal byte 2

  Scenario: Loading telnet codes defines line-ending constants
    Given I require the telnet codes library
    Then the telnet codes NULL constant should equal "\000"
    And the telnet codes CR constant should equal "\015"
    And the telnet codes LF constant should equal "\012"
    And the telnet codes EOL constant should equal CR followed by LF
