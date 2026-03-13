# frozen_string_literal: true

###############################################################################
# Step definitions for the Blind attribute feature.                            #
###############################################################################
require 'test/unit/assertions'

World(Test::Unit::Assertions)

###############################################################################
# Stub manager so GameObject can generate GOIDs without a real Manager.        #
###############################################################################
unless defined?(BlindStubManager)
  class BlindStubManager
    def existing_goid?(_goid)
      false
    end

    def submit_action(_action); end

    def get_object(_goid)
      nil
    end
  end
end

###############################################################################
# World module – holds scenario state for blind attribute tests                #
###############################################################################
module BlindWorld
  attr_accessor :blind_living_object, :blind_non_living_object,
                :blind_attribute, :blind_error, :blind_look_data
end
World(BlindWorld)

###############################################################################
# Given steps                                                                  #
###############################################################################
###############################################################################
# Helper: ensure top-level constants exist so that Blind and Attribute can     #
# resolve unqualified references to GameObject and LivingObject.               #
###############################################################################
###############################################################################
# Ensure ServerConfig exists (other step files may have already defined it).   #
###############################################################################
unless defined?(ServerConfig)
  BlindServerConfig = Object.new
  BlindServerConfig.instance_variable_set(:@data, {})
  class << BlindServerConfig
    def [](key); @data[key]; end
    def []=(key, value); @data[key] = value; end
  end
  Object.const_set(:ServerConfig, BlindServerConfig)
end

def blind_ensure_environment!
  ServerConfig[:log_level] ||= 0

  $manager ||= BlindStubManager.new
  # Mobile initialization calls $manager.get_object via Reacts
  unless $manager.respond_to?(:get_object)
    def $manager.get_object(_); nil; end
  end

  require 'aethyr/core/objects/mobile'
  require 'aethyr/core/objects/attributes/blind'

  # Blind references LivingObject and Attribute references GameObject at the
  # top level.  Other test step files may have already defined stub versions
  # of these constants; always (re)point them at the real classes so that
  # `is_a?` checks inside Attribute and Blind work correctly.
  if defined?(::GameObject) && ::GameObject != Aethyr::Core::Objects::GameObject
    Object.send(:remove_const, :GameObject)
  end
  Object.const_set(:GameObject, Aethyr::Core::Objects::GameObject) unless defined?(::GameObject)

  if defined?(::LivingObject) && ::LivingObject != Aethyr::Core::Objects::LivingObject
    Object.send(:remove_const, :LivingObject)
  end
  Object.const_set(:LivingObject, Aethyr::Core::Objects::LivingObject) unless defined?(::LivingObject)
end

Given('I have a non-living game object for blind testing') do
  blind_ensure_environment!
  self.blind_non_living_object = Aethyr::Core::Objects::GameObject.new(nil, nil, "rock")
end

Given('I have a living object for blind testing') do
  blind_ensure_environment!
  self.blind_living_object = Aethyr::Core::Objects::Mobile.new(nil, nil, "guard")
  # The noun method requires @gender to be set for pronoun resolution
  blind_living_object.instance_variable_set(:@gender, :masculine)
end

Given('I have a living object with the Blind attribute attached') do
  blind_ensure_environment!
  self.blind_living_object = Aethyr::Core::Objects::Mobile.new(nil, nil, "guard")
  blind_living_object.instance_variable_set(:@gender, :masculine)
  self.blind_attribute = Blind.new(blind_living_object)
end

###############################################################################
# When steps                                                                   #
###############################################################################
When('I try to attach the Blind attribute to the non-living object') do
  require 'aethyr/core/objects/attributes/blind'

  self.blind_error = nil
  begin
    Blind.new(blind_non_living_object)
  rescue ArgumentError => e
    self.blind_error = e
  end
end

When('I attach the Blind attribute to the living object') do
  require 'aethyr/core/objects/attributes/blind'

  self.blind_attribute = Blind.new(blind_living_object)
end

When('I call pre_look on the blind attribute with look data') do
  self.blind_look_data = { can_look: true }
  blind_attribute.pre_look(blind_look_data)
end

###############################################################################
# Then steps                                                                   #
###############################################################################
Then('the blind attribute should raise an ArgumentError about LivingObjects') do
  assert_not_nil(blind_error, 'Expected an ArgumentError to be raised')
  assert_kind_of(ArgumentError, blind_error)
  assert_match(/LivingObject/, blind_error.message,
               'Error message should mention LivingObjects')
end

Then('the blind attribute should be created successfully') do
  assert_not_nil(blind_attribute, 'Blind attribute should have been created')
  assert_kind_of(Blind, blind_attribute)
end

Then('the blind attribute should be attached to the living object') do
  assert_equal(blind_living_object, blind_attribute.attached_to,
               'Blind attribute should reference the living object')
end

Then('the look data should have can_look set to false') do
  assert_equal(false, blind_look_data[:can_look],
               'pre_look should set :can_look to false')
end

Then('the look data should have a reason explaining blindness') do
  reason = blind_look_data[:reason]
  assert_not_nil(reason, 'pre_look should set a :reason')
  assert_match(/cannot see/, reason, 'Reason should mention inability to see')
  assert_match(/blind/, reason, 'Reason should mention being blind')
end
