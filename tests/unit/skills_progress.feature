Feature: Smooth text-based progress-bar generation
  The Skills command helper should emit beautifully formatted,
  percentage-accurate progress bars for both the horizontal and
  vertical "smooth" styles.

    Background:
        Given I require the Skills command library

    Scenario Outline: Vertical smooth progress bar renders correctly at <pct> %
        Given a stubbed SkillsCommand instance with a single skill at <pct>%  
        When I invoke the SkillsCommand action
        Then the SkillsCommand result should contain a valid progress bar at <pct>%

        Examples:
            | pct |
            | 12  |
            | 37  |
            | 63  |
            | 88  |

    Scenario: Exercise generate_progress helper across the full 1/8 spectrum
        When I exercise the generate_progress helper across all thresholds 

    @vertical
    Scenario Outline: Vertical progress bar at <percentage>% complete
        Given I set the progress bar width to 20
        And I set the progress percentage to <percentage>
        And I use the "vertical_smooth" style
        When I build the progress bar
        Then the progress bar should include "<percentage>%"
        And the output should be correctly wrapped in raw colour tags
        And the bar should include the vertical smooth glyph for <percentage>%

        Examples:
            | percentage |
            | 0          |
            | 75         |
            | 100        |

    @horizontal
    Scenario: Horizontal progress bar at 75 %
        Given I set the progress bar width to 20
        And I set the progress percentage to 75
        And I use the "horizontal_smooth" style
        When I build the progress bar
        Then the progress bar should include "75%"
        And the output should be correctly wrapped in raw colour tags
        And the bar should include the horizontal smooth glyph for 75%
