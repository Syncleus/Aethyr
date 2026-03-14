# frozen_string_literal: true
###############################################################################
# Step definitions for Container and GridContainer game object coverage.       #
#                                                                             #
#   Covers: remove, find, include?, output, out_event (all branches),         #
#           look_inside, GridContainer#add, find_by_position, position.        #
###############################################################################
require 'test/unit/assertions'
require 'ostruct'

World(Test::Unit::Assertions)

###############################################################################
# Stub manager – must exist before Container (via GameObject) is loaded.       #
###############################################################################
unless defined?(ContStubManager)
  class ContStubManager
    def existing_goid?(_goid); false; end
    def find(_id); nil; end
    def submit_action(_action); end
  end
end

###############################################################################
# Ensure ServerConfig exists (needed by Guid / log transitive deps).           #
###############################################################################
unless defined?(::ServerConfig)
  module ::ServerConfig
    @data = {}
    class << self
      def [](key);       @data[key]; end
      def []=(key, val); @data[key] = val; end
    end
  end
end

###############################################################################
# Set $manager *before* requiring Container so Guid generation works.          #
###############################################################################
$manager ||= ContStubManager.new

###############################################################################
# Ensure the bare Reacts constant is defined for the is_a? check in out_event. #
# If the real module is already loaded, skip; otherwise define a minimal stub. #
###############################################################################
unless defined?(::Reacts)
  module ::Reacts; end
end

###############################################################################
# Require the actual Container class (and its transitive dependencies).        #
###############################################################################
require 'aethyr/core/objects/container'

###############################################################################
# World module – scenario-scoped state                                         #
###############################################################################
module ContainerTestWorld
  attr_accessor :cont_container, :cont_grid_container,
                :cont_object, :cont_object2, :cont_result,
                :cont_player, :cont_target,
                :cont_grid_object, :cont_grid_result,
                :cont_reacts_container, :cont_reacts_alerted
end
World(ContainerTestWorld)

###############################################################################
# Lightweight test doubles                                                     #
###############################################################################

# A minimal game-object double with the interface used by Container methods.
# Must pass is_a?(Aethyr::Core::Objects::GameObject) so Gary#delete works.
class ContTestObj
  attr_accessor :game_object_id, :container, :name, :alt_names, :generic,
                :visible, :quantity, :article, :short_desc
  alias :goid :game_object_id

  def initialize(opts = {})
    @game_object_id = opts[:goid] || "cont_obj_#{rand(99999)}"
    @name           = opts[:name] || "thing"
    @alt_names      = opts[:alt_names] || []
    @generic        = opts[:generic] || "thing"
    @visible        = true
    @quantity       = 1
    @article        = "a"
    @short_desc     = ""
    @container      = nil
    @alerts         = []
    @outputs        = []
    @out_events     = []
  end

  def alert(event);    @alerts << event;     end
  def output(msg, *_); @outputs << msg;      end
  def out_event(event); @out_events << event; end

  def alerts;     @alerts;     end
  def outputs;    @outputs;    end
  def out_events; @out_events; end

  # Needed by Inventory (Gary) – keyed by game_object_id
  def plural; "#{@name}s"; end

  # Gary#delete checks is_a?(Aethyr::Core::Objects::GameObject) to extract goid
  def is_a?(klass)
    return true if klass == Aethyr::Core::Objects::GameObject
    super
  end
end

# A player double that also records output and out_event.
class ContTestPlayer < ContTestObj
  def initialize(opts = {})
    super(opts.merge(name: opts[:name] || "TestPlayer"))
  end
end

###############################################################################
# Given steps                                                                  #
###############################################################################

Given('a stubbed Container test environment') do
  @cont_container = Aethyr::Core::Objects::Container.new
  @cont_object    = nil
  @cont_object2   = nil
  @cont_result    = nil
  @cont_player    = nil
  @cont_target    = nil
end

Given('a stubbed GridContainer test environment') do
  @cont_grid_container = Aethyr::Core::Objects::GridContainer.new
  @cont_grid_object    = nil
  @cont_grid_result    = nil
end

Given('an object is in the container') do
  @cont_object = ContTestObj.new(goid: "obj_1", name: "widget")
  @cont_container.add(@cont_object)
end

Given('an object named {string} is in the container') do |name|
  @cont_object = ContTestObj.new(goid: "obj_named_#{name}", name: name)
  @cont_container.add(@cont_object)
end

Given('two objects are in the container') do
  @cont_object  = ContTestObj.new(goid: "obj_a", name: "alpha")
  @cont_object2 = ContTestObj.new(goid: "obj_b", name: "beta")
  @cont_container.add(@cont_object)
  @cont_container.add(@cont_object2)
end

Given('a player object is in the container') do
  @cont_player = ContTestPlayer.new(goid: "player_1", name: "Hero")
  @cont_container.add(@cont_player)
end

Given('a target object is in the container') do
  @cont_target = ContTestObj.new(goid: "target_1", name: "Villain")
  @cont_container.add(@cont_target)
end

Given('another object is in the container') do
  @cont_object2 = ContTestObj.new(goid: "obj_other", name: "bystander")
  @cont_container.add(@cont_object2)
end

Given('a Reacts-enabled container with an object inside') do
  @cont_reacts_container = Aethyr::Core::Objects::Container.new
  # Extend the container instance with Reacts so is_a?(Reacts) returns true
  @cont_reacts_container.extend(::Reacts)
  @cont_reacts_alerted = false

  # Override the alert method to record that it was called
  orig_alert = @cont_reacts_container.method(:alert)
  @cont_reacts_alerted_ref = -> { @cont_reacts_alerted }
  @cont_reacts_alerted_set = ->(v) { @cont_reacts_alerted = v }
  alerted_set = @cont_reacts_alerted_set

  @cont_reacts_container.define_singleton_method(:alert) do |event|
    alerted_set.call(true)
  end

  obj = ContTestObj.new(goid: "reacts_obj_1", name: "reactive_item")
  @cont_reacts_container.add(obj)
end

Given('an object is added to the grid container at position {int}') do |pos|
  @cont_grid_object = ContTestObj.new(goid: "grid_obj_1", name: "grid_widget")
  @cont_grid_container.add(@cont_grid_object, pos)
end

###############################################################################
# When steps                                                                   #
###############################################################################

When('I send an alert event to the container') do
  @cont_alert_event = { action: :test_alert }
  @cont_container.alert(@cont_alert_event)
end

When('I remove the object from the container') do
  @cont_container.remove(@cont_object)
end

When('I find {string} in the container') do |name|
  @cont_result = @cont_container.find(name)
end

When('I check if the container includes the object') do
  @cont_result = @cont_container.include?(@cont_object.goid)
end

When('I check if the container includes a missing id') do
  @cont_result = @cont_container.include?("nonexistent_id_999")
end

When('I send output {string} to the container') do |message|
  @cont_container.output(message)
end

When('I send output {string} to the container skipping the first object') do |message|
  @cont_container.output(message, @cont_object)
end

When('I send an out_event with to_player set') do
  event = {
    to_player: "You see something.",
    player: @cont_player,
    to_other: "Someone does something."
  }
  @cont_container.out_event(event)
end

When('I send an out_event with to_target set') do
  event = {
    to_target: "Something happens to you.",
    target: @cont_target,
    to_other: "Something happens."
  }
  @cont_container.out_event(event)
end

When('I send an out_event on the Reacts container') do
  event = { to_other: "An event occurs." }
  @cont_reacts_container.out_event(event)
end

When('I send an out_event skipping the first object') do
  event = { to_other: "A skipped event." }
  @cont_container.out_event(event, @cont_object)
end

When('a player looks inside the container') do
  @cont_player = ContTestPlayer.new(goid: "looker_1", name: "Looker")
  event = { player: @cont_player }
  @cont_container.look_inside(event)
end

When('I add an object to the grid container at position {int}') do |pos|
  @cont_grid_object = ContTestObj.new(goid: "grid_add_1", name: "grid_thing")
  @cont_grid_container.add(@cont_grid_object, pos)
end

When('I find by position {int} in the grid container') do |pos|
  @cont_grid_result = @cont_grid_container.find_by_position(pos)
end

When('I query the position of the object in the grid container') do
  @cont_grid_result = @cont_grid_container.position(@cont_grid_object)
end

###############################################################################
# Then steps                                                                   #
###############################################################################

Then('all objects should have received the alert event') do
  [@cont_object, @cont_object2].each do |obj|
    assert(obj.alerts.include?(@cont_alert_event),
           "Expected #{obj.name} to receive alert event, got: #{obj.alerts.inspect}")
  end
end

Then('the object should no longer be in the container') do
  assert(!@cont_container.include?(@cont_object.goid),
         "Expected object to be removed from container")
end

Then('the removed object container should be nil') do
  assert_nil(@cont_object.container,
             "Expected removed object's container to be nil, got #{@cont_object.container.inspect}")
end

Then('the find result should be the object named {string}') do |name|
  # Container#find passes through to inventory.find which may return nil
  # if the object is found by name. The inventory uses Gary#find which
  # searches by name/alt_names/generic.
  # We assert it's not nil and has the right name.
  assert_not_nil(@cont_result, "Expected find to return an object, got nil")
  assert_equal(name, @cont_result.name,
               "Expected found object named '#{name}', got '#{@cont_result.name}'")
end

Then('the find result should be nil') do
  assert_nil(@cont_result, "Expected find result to be nil, got #{@cont_result.inspect}")
end

Then('the include result should be true') do
  assert_equal(true, @cont_result, "Expected include? to return true")
end

Then('the include result should be false') do
  assert_equal(false, @cont_result, "Expected include? to return false")
end

Then('all objects should have received the output {string}') do |message|
  [@cont_object, @cont_object2].each do |obj|
    assert(obj.outputs.include?(message),
           "Expected #{obj.name} to receive output '#{message}', got: #{obj.outputs.inspect}")
  end
end

Then('the first object should not have received the output') do
  assert(@cont_object.outputs.empty?,
         "Expected first object to NOT receive output, but got: #{@cont_object.outputs.inspect}")
end

Then('the second object should have received the output {string}') do |message|
  assert(@cont_object2.outputs.include?(message),
         "Expected second object to receive output '#{message}', got: #{@cont_object2.outputs.inspect}")
end

Then('the player should have received the out_event') do
  assert(!@cont_player.out_events.empty?,
         "Expected player to receive out_event but got none")
end

Then('the other object should have received the out_event') do
  assert(!@cont_object2.out_events.empty?,
         "Expected other object to receive out_event but got none")
end

Then('the target should have received the out_event') do
  assert(!@cont_target.out_events.empty?,
         "Expected target to receive out_event but got none")
end

Then('the player should have received exactly one out_event') do
  assert_equal(1, @cont_player.out_events.length,
               "Expected player to receive exactly 1 out_event, got #{@cont_player.out_events.length}")
end

Then('the Reacts container should have been alerted') do
  assert(@cont_reacts_alerted,
         "Expected Reacts container to have been alerted via self.alert")
end

Then('the first object should not have received the out_event') do
  assert(@cont_object.out_events.empty?,
         "Expected first object to NOT receive out_event, but got: #{@cont_object.out_events.inspect}")
end

Then('the second object should have received the out_event via out_event') do
  assert(!@cont_object2.out_events.empty?,
         "Expected second object to receive out_event but got none")
end

Then('the player should see the container name and inventory listing') do
  # look_inside calls: event[:player].output("#{self.name} contains:\n" << @inventory.show)
  assert(!@cont_player.outputs.empty?,
         "Expected player to receive output from look_inside")
  msg = @cont_player.outputs.last
  assert(msg.include?("contains:"),
         "Expected output to include 'contains:', got: #{msg.inspect}")
end

Then('the grid object should be in the grid container') do
  assert(@cont_grid_container.include?(@cont_grid_object.goid),
         "Expected grid container to include the object")
end

Then('the grid object container should be the grid container id') do
  assert_equal(@cont_grid_container.game_object_id, @cont_grid_object.container,
               "Expected grid object's container to be grid container's goid")
end

Then('the grid find result should be the added object') do
  assert_equal(@cont_grid_object, @cont_grid_result,
               "Expected find_by_position to return the added object")
end

Then('the grid position result should be {int}') do |expected_pos|
  assert_equal(expected_pos, @cont_grid_result,
               "Expected position to be #{expected_pos}, got #{@cont_grid_result.inspect}")
end
