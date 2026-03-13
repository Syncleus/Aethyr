Feature: Attribute base class
  The Attribute class is the base class for all attributes that can be
  attached to a GameObject. It validates the target and registers itself.

  Scenario: Initialising an Attribute with a valid GameObject
    Given I require the Attribute library
    And I have a mock game object for attribute attachment
    When I create a new Attribute attached to the mock game object
    Then the attribute should store the attached game object
    And the game object should have the attribute registered

  Scenario: Initialising an Attribute with a non-GameObject raises ArgumentError
    Given I require the Attribute library
    When I try to create an Attribute with a plain string
    Then an ArgumentError should be raised with message "Can only attach attributes to game objects"
