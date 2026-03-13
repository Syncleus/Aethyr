# frozen_string_literal: true

###############################################################################
# Step definitions for the Attribute base class feature.                       #
###############################################################################
require 'test/unit/assertions'

World(Test::Unit::Assertions)

###############################################################################
# Helpers and stubs                                                            #
###############################################################################
module AttributeWorld
  # Minimal GameObject stub that satisfies `is_a? GameObject` and provides
  # the `attach_attribute` method the Attribute constructor calls.
  class MockGameObject < GameObject
    attr_reader :attached_attributes

    def initialize
      @attached_attributes = []
    end

    def attach_attribute(attr)
      @attached_attributes << attr
    end
  end

  attr_accessor :attribute_instance, :mock_game_object
end
World(AttributeWorld)

###############################################################################
# Given steps                                                                  #
###############################################################################
Given('I require the Attribute library') do
  # Ensure a top-level GameObject constant exists (other step files may
  # already have defined it; guard to avoid redefinition warnings).
  unless defined?(::GameObject)
    Object.const_set(:GameObject, Class.new {
      def attach_attribute(_attr); end
    })
  end
  require 'aethyr/core/objects/attributes/attribute'
end

Given('I have a mock game object for attribute attachment') do
  self.mock_game_object = AttributeWorld::MockGameObject.new
end

###############################################################################
# When steps                                                                   #
###############################################################################
When('I create a new Attribute attached to the mock game object') do
  self.attribute_instance = Attribute.new(mock_game_object)
end

When('I try to create an Attribute with a plain string') do
  @exception = nil
  begin
    Attribute.new("not a game object")
  rescue ArgumentError => e
    @exception = e
  end
end

###############################################################################
# Then steps                                                                   #
###############################################################################
Then('the attribute should store the attached game object') do
  assert_not_nil(attribute_instance, 'Expected attribute to be created')
  assert_equal(mock_game_object, attribute_instance.attached_to,
               'Expected attached_to to reference the mock game object')
end

Then('the game object should have the attribute registered') do
  assert_includes(mock_game_object.attached_attributes, attribute_instance,
                  'Expected the game object to have the attribute registered via attach_attribute')
end


