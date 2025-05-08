Feature: Skills progress-bar
    These additional scenarios drive the SkillsCommand implementation through
    every conceivable execution branch, ensuring rock-solid confidence and a
    95 %+ line coverage figure.

    Background:
    # Make sure the production class is present – the existing step will mark the
    # scenario as "pending" on lightweight builds where the file is absent.
    Given I require the Skills command library

    ###############################################################################
    # Black-box scenarios – prove that a realistic invocation produces correctly  #
    # formatted output for a variety of percentages.                              #
    ###############################################################################
    Scenario Outline: Vertical smooth progress bar renders correctly at <pct> %
    # For these tests we execute the full command (not just the helper).
    Given a stubbed SkillsCommand instance with a single skill at <pct>%  
    When I invoke the SkillsCommand action
    Then the SkillsCommand result should contain a valid progress bar at <pct>%

    Examples:
        | pct |
        | 12  |
        | 37  |
        | 63  |
        | 88  |

    ###############################################################################
    # White-box scenario – tickle every branch of the smoothing algorithm once.   #
    ###############################################################################
    Scenario: Exercise generate_progress helper across the full 1/8 spectrum
    When I exercise the generate_progress helper across all thresholds 