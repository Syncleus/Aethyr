Feature: HasInventory trait
  The HasInventory module provides inventory management and search capabilities
  to game objects that include it.

  # ── search_inv: item found in inventory ──────────────────────────────────

  Scenario: search_inv returns the item when found in inventory
    Given a has_inventory test object
    And an item named "sword" is in the has_inventory object inventory
    When I search_inv for "sword" on the has_inventory object
    Then the has_inventory search result should be the item named "sword"

  # ── search_inv: item not found, no equipment ─────────────────────────────

  Scenario: search_inv returns nil when item is not found and object has no equipment
    Given a has_inventory test object
    When I search_inv for "ghost" on the has_inventory object
    Then the has_inventory search result should be nil

  # ── search_inv: item not found in inventory, found in equipment ──────────

  Scenario: search_inv falls back to equipment when item is not in inventory
    Given a has_inventory test object with equipment
    And an item named "helmet" is in the has_inventory object equipment
    When I search_inv for "helmet" on the has_inventory object
    Then the has_inventory search result should be the item named "helmet"

  # ── search_inv: item not found in inventory or equipment ─────────────────

  Scenario: search_inv returns nil when item is not in inventory or equipment
    Given a has_inventory test object with equipment
    When I search_inv for "phantom" on the has_inventory object
    Then the has_inventory search result should be nil
