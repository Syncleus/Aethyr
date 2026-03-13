Feature: Blind attribute
  The Blind attribute is attached to LivingObjects to prevent them from looking.
  It subscribes to the attached object and provides a pre_look hook that blocks
  vision with an appropriate message.

  Scenario: Creating a Blind attribute with a non-LivingObject raises an error
    Given I have a non-living game object for blind testing
    When I try to attach the Blind attribute to the non-living object
    Then the blind attribute should raise an ArgumentError about LivingObjects

  Scenario: Creating a Blind attribute with a LivingObject succeeds
    Given I have a living object for blind testing
    When I attach the Blind attribute to the living object
    Then the blind attribute should be created successfully
    And the blind attribute should be attached to the living object

  Scenario: The pre_look method blocks looking with a reason
    Given I have a living object with the Blind attribute attached
    When I call pre_look on the blind attribute with look data
    Then the look data should have can_look set to false
    And the look data should have a reason explaining blindness
