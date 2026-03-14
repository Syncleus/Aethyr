Feature: Skill value object behaviour
  The Skill class tracks a character's skill name, XP, and provides
  derived calculations such as level, XP progress, and percentage.

  Background:
    Given I require the Skill class

  Scenario: A new skill starts at level 1 with zero XP
    Given a skill named "Swordsmanship" with 0 xp
    Then the skill level should be 1
    And the skill xp_so_far should be 0
    And the skill xp_per_level should be 10000
    And the skill xp_to_go should be 10000
    And the skill level_percentage should be 0.0

  Scenario: A skill with partial XP reports correct progress
    Given a skill named "Archery" with 5000 xp
    Then the skill level should be 1
    And the skill xp_so_far should be 5000
    And the skill xp_per_level should be 10000
    And the skill xp_to_go should be 5000
    And the skill level_percentage should be 0.5

  Scenario: A skill with exactly 10000 XP reaches level 2
    Given a skill named "Stealth" with 10000 xp
    Then the skill level should be 2
    And the skill xp_so_far should be 0
    And the skill xp_to_go should be 10000
    And the skill level_percentage should be 0.0

  Scenario: A skill with 25000 XP is at level 3 with 5000 towards next
    Given a skill named "Magic" with 25000 xp
    Then the skill level should be 3
    And the skill xp_so_far should be 5000
    And the skill xp_to_go should be 5000
    And the skill level_percentage should be 0.5

  Scenario: Adding XP increases the skill's total XP
    Given a skill named "Cooking" with 100 xp
    When I add 250 xp to the skill
    Then the skill xp should be 350
    And the skill level should be 1
