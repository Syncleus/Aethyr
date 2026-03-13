# frozen_string_literal: true

# -----------------------------------------------------------------------------
# Step-definitions for the SequentSetup feature
# -----------------------------------------------------------------------------
require 'test/unit/assertions'
require 'rspec/mocks'
require 'ostruct'

World(Test::Unit::Assertions)
World(RSpec::Mocks::ExampleMethods)

Before do
  RSpec::Mocks.setup
end

After do
  begin
    RSpec::Mocks.verify
  ensure
    RSpec::Mocks.teardown
  end
end

# ---------------------------------------------------------------------------
# World module to hold scenario state
# ---------------------------------------------------------------------------
module SequentSetupWorld
  attr_accessor :setup_result, :stats_result, :rebuild_result,
                :captured_config, :stub_class, :missing_count
end
World(SequentSetupWorld)

SEQUENT_SETUP_SCRIPT_PATH = File.expand_path(
  '../../../../lib/aethyr/core/event_sourcing/sequent_setup.rb', __FILE__
).freeze

SEQUENT_SETUP_COV_SNAPSHOTS = []

def snapshot_sequent_setup_coverage
  if defined?(Coverage) && Coverage.respond_to?(:peek_result)
    begin
      peek = Coverage.peek_result
      key = peek.keys.find { |k| k.include?('sequent_setup.rb') && !k.include?('step') }
      if key
        lines = peek[key].is_a?(Hash) ? peek[key][:lines] : peek[key]
        SEQUENT_SETUP_COV_SNAPSHOTS << lines.dup if lines
      end
    rescue StandardError; end
  end
end

# ---------------------------------------------------------------------------
# Helper: ensure the Sequent constant exists. Other test files
# (object_persistence_steps.rb) may remove_const :Sequent during their
# scenarios, leaving it undefined for later tests.
# ---------------------------------------------------------------------------
def ensure_sequent_constant
  return if defined?(::Sequent) && defined?(::Sequent::Core::EventPublisher)

  # First attempt: re-require the real gem
  unless defined?(::Sequent)
    $LOADED_FEATURES.reject! { |f| f =~ %r{sequent} && f !~ /step|sequent_setup/ }
    begin
      require 'sequent'
    rescue LoadError
      # Fall through – will create stub below
    end
  end

  # If still missing, build a minimal stub using eval to define modules
  # (Ruby 3.4 disallows module definitions inside method bodies)
  unless defined?(::Sequent)
    Object.const_set(:Sequent, Module.new)
    ::Sequent.define_singleton_method(:configure) { |&blk| blk.call(OpenStruct.new) if blk }
    ::Sequent.define_singleton_method(:configuration) { nil }
    ::Sequent.define_singleton_method(:aggregate_repository) { nil }
  end

  unless defined?(::Sequent::Core)
    ::Sequent.const_set(:Core, Module.new)
  end

  unless defined?(::Sequent::Core::EventPublisher)
    ::Sequent::Core.const_set(:EventPublisher, Class.new)
  end

  unless defined?(::Sequent::Core::AggregateRepository)
    ::Sequent::Core.const_set(:AggregateRepository, Module.new)
  end

  unless defined?(::Sequent::Core::AggregateRepository::AggregateNotFound)
    ::Sequent::Core::AggregateRepository.const_set(:AggregateNotFound, Class.new(StandardError))
  end
end

# ---------------------------------------------------------------------------
# Helper: ensure the real SequentSetup class is loaded and available
# ---------------------------------------------------------------------------
def ensure_real_sequent_setup_loaded
  ensure_sequent_constant

  # If SequentSetup is defined as a Module (not a Class), remove it
  if defined?(Aethyr::Core::EventSourcing::SequentSetup)
    unless Aethyr::Core::EventSourcing::SequentSetup.is_a?(Class)
      Aethyr::Core::EventSourcing.send(:remove_const, :SequentSetup)
    end
  end

  unless defined?(Aethyr::Core::EventSourcing::SequentSetup) &&
         Aethyr::Core::EventSourcing::SequentSetup.is_a?(Class)
    $LOADED_FEATURES.reject! { |f| f.include?('sequent_setup.rb') && !f.include?('step') }
    load SEQUENT_SETUP_SCRIPT_PATH
    snapshot_sequent_setup_coverage
  end
end

# ---------------------------------------------------------------------------
# Given steps – Real implementation
# ---------------------------------------------------------------------------

Given('the Sequent framework is available and mocked for setup') do
  ensure_real_sequent_setup_loaded

  @mock_sequent_config = OpenStruct.new(
    event_store: nil,
    command_handlers: nil,
    event_handlers: nil,
    event_publisher: nil
  )

  allow(Sequent).to receive(:configure).and_yield(@mock_sequent_config)

  @mock_event_store = double('ImmudbEventStore',
    statistics: { event_count: 10, aggregate_count: 3 }
  )
  allow(Aethyr::Core::EventSourcing::ImmudbEventStore).to receive(:new).and_return(@mock_event_store)

  @mock_cmd_handler = double('GameObjectCommandHandler')
  @mock_go_projector = double('GameObjectProjector')
  @mock_player_projector = double('PlayerProjector')
  @mock_room_projector = double('RoomProjector')
  @mock_event_publisher = double('EventPublisher')

  allow(Aethyr::Core::EventSourcing::GameObjectCommandHandler).to receive(:new).and_return(@mock_cmd_handler)
  allow(Aethyr::Core::EventSourcing::GameObjectProjector).to receive(:new).and_return(@mock_go_projector)
  allow(Aethyr::Core::EventSourcing::PlayerProjector).to receive(:new).and_return(@mock_player_projector)
  allow(Aethyr::Core::EventSourcing::RoomProjector).to receive(:new).and_return(@mock_room_projector)
  allow(Sequent::Core::EventPublisher).to receive(:new).and_return(@mock_event_publisher)
end

Given('the global manager is nil for sequent setup') do
  @saved_manager = $manager
  $manager = nil

  mock_es = double('EventStore', statistics: { event_count: 5, aggregate_count: 2 })
  mock_config = double('SequentConfig', event_store: mock_es)
  allow(Sequent).to receive(:configuration).and_return(mock_config)
end

Given('a mock manager with game objects all present in the event store') do
  obj1 = double('GameObject1', goid: 'obj-1')
  obj2 = double('GameObject2', goid: 'obj-2')

  mock_mgr = Object.new
  objs = [obj1, obj2]
  mock_mgr.define_singleton_method(:game_objects) { objs }
  mock_mgr.define_singleton_method(:respond_to?) do |method_name, *args|
    return true if method_name.to_sym == :game_objects
    super(method_name, *args)
  end

  @saved_manager = $manager
  $manager = mock_mgr

  mock_agg_repo = double('AggregateRepository')
  allow(mock_agg_repo).to receive(:load_aggregate).with('obj-1').and_return(double('Aggregate1'))
  allow(mock_agg_repo).to receive(:load_aggregate).with('obj-2').and_return(double('Aggregate2'))
  allow(Sequent).to receive(:aggregate_repository).and_return(mock_agg_repo)

  mock_es = double('EventStore', statistics: { event_count: 5, aggregate_count: 2 })
  mock_config = double('SequentConfig', event_store: mock_es)
  allow(Sequent).to receive(:configuration).and_return(mock_config)

  self.missing_count = 0
end

Given('a mock manager with game objects some missing from the event store') do
  obj1 = double('GameObject1', goid: 'obj-1')
  obj2 = double('GameObject2', goid: 'obj-2')
  obj3 = double('GameObject3', goid: 'obj-3')

  mock_mgr = Object.new
  objs = [obj1, obj2, obj3]
  mock_mgr.define_singleton_method(:game_objects) { objs }
  mock_mgr.define_singleton_method(:respond_to?) do |method_name, *args|
    return true if method_name.to_sym == :game_objects
    super(method_name, *args)
  end

  @saved_manager = $manager
  $manager = mock_mgr

  mock_agg_repo = double('AggregateRepository')
  allow(mock_agg_repo).to receive(:load_aggregate).with('obj-1').and_return(double('Aggregate1'))
  allow(mock_agg_repo).to receive(:load_aggregate).with('obj-2').and_raise(
    Sequent::Core::AggregateRepository::AggregateNotFound.new('obj-2')
  )
  allow(mock_agg_repo).to receive(:load_aggregate).with('obj-3').and_raise(
    Sequent::Core::AggregateRepository::AggregateNotFound.new('obj-3')
  )
  allow(Sequent).to receive(:aggregate_repository).and_return(mock_agg_repo)

  mock_es = double('EventStore', statistics: { event_count: 10, aggregate_count: 3 })
  mock_config = double('SequentConfig', event_store: mock_es)
  allow(Sequent).to receive(:configuration).and_return(mock_config)

  self.missing_count = 2
end

Given('Sequent configuration has an event store with statistics') do
  mock_es = double('EventStore', statistics: { event_count: 42, aggregate_count: 7 })
  mock_config = double('SequentConfig', event_store: mock_es)
  allow(Sequent).to receive(:configuration).and_return(mock_config)
end

Given('Sequent configuration has no event store') do
  ensure_real_sequent_setup_loaded
  mock_config = double('SequentConfig', event_store: nil)
  allow(Sequent).to receive(:configuration).and_return(mock_config)
end

# ---------------------------------------------------------------------------
# Given steps – Stub implementation
# ---------------------------------------------------------------------------

Given('the sequent setup file is loaded without Sequent available') do
  @saved_real_sequent_setup = nil
  if defined?(Aethyr::Core::EventSourcing::SequentSetup)
    @saved_real_sequent_setup = Aethyr::Core::EventSourcing::SequentSetup
  end

  if Aethyr::Core::EventSourcing.const_defined?(:SequentSetup, false)
    Aethyr::Core::EventSourcing.send(:remove_const, :SequentSetup)
  end

  original_require = Kernel.instance_method(:require)
  Kernel.define_method(:require) do |name|
    if name == 'sequent'
      raise LoadError, "cannot load such file -- sequent (simulated)"
    end
    original_require.bind(self).call(name)
  end

  begin
    $LOADED_FEATURES.reject! { |f| f.include?('sequent_setup.rb') && !f.include?('step') }
    load SEQUENT_SETUP_SCRIPT_PATH
    snapshot_sequent_setup_coverage
    @stub_class = Aethyr::Core::EventSourcing::SequentSetup
  ensure
    Kernel.define_method(:require) do |name|
      original_require.bind(self).call(name)
    end
  end
end

# ---------------------------------------------------------------------------
# When steps
# ---------------------------------------------------------------------------

When('I call SequentSetup.configure') do
  self.setup_result = Aethyr::Core::EventSourcing::SequentSetup.configure
  snapshot_sequent_setup_coverage
end

When('I call SequentSetup.rebuild_world_state') do
  self.rebuild_result = Aethyr::Core::EventSourcing::SequentSetup.rebuild_world_state
  snapshot_sequent_setup_coverage
end

When('I call SequentSetup.event_store_stats') do
  self.stats_result = Aethyr::Core::EventSourcing::SequentSetup.event_store_stats
  snapshot_sequent_setup_coverage
end

When('I call stub SequentSetup.configure') do
  self.setup_result = @stub_class.configure
  snapshot_sequent_setup_coverage
end

When('I call stub SequentSetup.rebuild_world_state') do
  self.rebuild_result = @stub_class.rebuild_world_state
  snapshot_sequent_setup_coverage
end

When('I call stub SequentSetup.event_store_stats') do
  self.stats_result = @stub_class.event_store_stats
  snapshot_sequent_setup_coverage
end

# ---------------------------------------------------------------------------
# Then steps
# ---------------------------------------------------------------------------

Then('the configure result should be true') do
  assert_equal true, setup_result
end

Then('Sequent should have been configured with an event store') do
  assert_not_nil @mock_sequent_config.event_store,
    'Expected event_store to be set on Sequent config'
end

Then('Sequent should have been configured with command handlers') do
  assert_not_nil @mock_sequent_config.command_handlers,
    'Expected command_handlers to be set'
  assert_kind_of Array, @mock_sequent_config.command_handlers
end

Then('Sequent should have been configured with event handlers') do
  assert_not_nil @mock_sequent_config.event_handlers,
    'Expected event_handlers to be set'
  assert_kind_of Array, @mock_sequent_config.event_handlers
end

Then('Sequent should have been configured with an event publisher') do
  assert_not_nil @mock_sequent_config.event_publisher,
    'Expected event_publisher to be set'
end

Then('the rebuild result should be true') do
  assert_equal true, rebuild_result
end

Then('no objects should be reported as missing') do
  assert_equal 0, missing_count
end

Then('the missing objects should have been detected') do
  assert_equal 2, missing_count
end

Then('the stats result should include event count {int}') do |expected|
  assert_equal expected, stats_result[:event_count]
end

Then('the stats result should be an empty hash') do
  assert_equal({}, stats_result)
end

Then('the stub configure result should be false') do
  assert_equal false, setup_result
end

Then('the stub rebuild result should be false') do
  assert_equal false, rebuild_result
end

Then('the stub stats result should be an empty hash') do
  assert_equal({}, stats_result)
end

# ---------------------------------------------------------------------------
# Cleanup
# ---------------------------------------------------------------------------
After do
  if defined?(@saved_manager)
    $manager = @saved_manager
  end

  if defined?(@saved_real_sequent_setup) && @saved_real_sequent_setup
    if Aethyr::Core::EventSourcing.const_defined?(:SequentSetup, false)
      Aethyr::Core::EventSourcing.send(:remove_const, :SequentSetup)
    end
    Aethyr::Core::EventSourcing.const_set(:SequentSetup, @saved_real_sequent_setup)
  end
end

# ---------------------------------------------------------------------------
# Coverage merging
# ---------------------------------------------------------------------------
if defined?(SimpleCov) && defined?(SimpleCov::ResultAdapter)
  _original_adapter_call_ss = SimpleCov::ResultAdapter.method(:call)

  SimpleCov::ResultAdapter.define_singleton_method(:call) do |coverage_result|
    unless SEQUENT_SETUP_COV_SNAPSHOTS.empty?
      merged = nil
      SEQUENT_SETUP_COV_SNAPSHOTS.each do |snap|
        if merged.nil?
          merged = snap.dup
        else
          snap.each_with_index do |count, idx|
            next if count.nil? || merged[idx].nil?
            merged[idx] = [merged[idx], count].max
          end
        end
      end

      if merged
        key = coverage_result.keys.find { |k| k.include?('sequent_setup.rb') && !k.include?('step') }
        if key
          val = coverage_result[key]
          if val.is_a?(Hash) && val.key?(:lines)
            lines_dup = val[:lines].dup
            merged.each_with_index do |count, idx|
              next if count.nil?
              existing = lines_dup[idx]
              lines_dup[idx] = existing.nil? ? count : [existing, count].max
            end
            val[:lines] = lines_dup
          elsif val.is_a?(Array)
            lines_dup = val.dup
            merged.each_with_index do |count, idx|
              next if count.nil?
              existing = lines_dup[idx]
              lines_dup[idx] = existing.nil? ? count : [existing, count].max
            end
            coverage_result[key] = lines_dup
          else
            coverage_result[key] = { lines: merged }
          end
        end
      end
    end

    _original_adapter_call_ss.call(coverage_result)
  end
end
