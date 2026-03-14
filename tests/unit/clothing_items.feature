Feature: Clothing item objects
  All clothing item subclasses initialise with correct default attributes,
  include the Wearable module, and descend from GenericClothing / GameObject.

  # ── Shoes ─────────────────────────────────────────────────────────
  Scenario: Shoes initialises with correct default attributes
    Given I require the ClothingItems library
    When I create a new Shoes object
    Then the Shoes generic should be "normal shoes"
    And the Shoes article should be "a pair of"
    And the Shoes position should be :feet
    And the Shoes layer should be 2
    And the Shoes should be movable

  Scenario: Shoes is an instance of GenericClothing and includes Wearable
    Given I require the ClothingItems library
    When I create a new Shoes object
    Then the Shoes should be a kind of GenericClothing
    And the Shoes should include Wearable

  # ── Glove ─────────────────────────────────────────────────────────
  Scenario: Glove initialises with correct default attributes
    Given I require the ClothingItems library
    When I create a new Glove object
    Then the Glove generic should be "leather gloves"
    And the Glove position should be :hand
    And the Glove layer should be 2
    And the Glove should be movable

  Scenario: Glove is an instance of GenericClothing and includes Wearable
    Given I require the ClothingItems library
    When I create a new Glove object
    Then the Glove should be a kind of GenericClothing
    And the Glove should include Wearable

  # ── Necklace ──────────────────────────────────────────────────────
  Scenario: Necklace initialises with correct default attributes
    Given I require the ClothingItems library
    When I create a new Necklace object
    Then the Necklace generic should be "silver necklace"
    And the Necklace position should be :neck
    And the Necklace layer should be 0
    And the Necklace should be movable

  Scenario: Necklace is an instance of GenericClothing and includes Wearable
    Given I require the ClothingItems library
    When I create a new Necklace object
    Then the Necklace should be a kind of GenericClothing
    And the Necklace should include Wearable

  # ── Belt ──────────────────────────────────────────────────────────
  Scenario: Belt initialises with correct default attributes
    Given I require the ClothingItems library
    When I create a new Belt object
    Then the Belt generic should be "belt"
    And the Belt position should be :waist
    And the Belt layer should be 0
    And the Belt should be movable

  Scenario: Belt is an instance of GenericClothing and includes Wearable
    Given I require the ClothingItems library
    When I create a new Belt object
    Then the Belt should be a kind of GenericClothing
    And the Belt should include Wearable

  # ── Breastplate ───────────────────────────────────────────────────
  Scenario: Breastplate initialises with correct default attributes
    Given I require the ClothingItems library
    When I create a new Breastplate object
    Then the Breastplate generic should be "breastplate"
    And the Breastplate position should be :torso
    And the Breastplate layer should be 1
    And the Breastplate should be movable

  Scenario: Breastplate is an instance of GenericClothing and includes Wearable
    Given I require the ClothingItems library
    When I create a new Breastplate object
    Then the Breastplate should be a kind of GenericClothing
    And the Breastplate should include Wearable
