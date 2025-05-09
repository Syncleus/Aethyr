# features/step_definitions/command_handler_steps.rb
# frozen_string_literal: true
################################################################################
# Generic validation steps for *any* concrete subclass of                      #
#   Aethyr::Extend::CommandHandler                                             #
#                                                                              #
# The design follows SOLID principles:                                         #
#                                                                              #
#   • SRP – Each step focuses on exactly one piece of assertion logic.         #
#   • OCP – Handler production code remains untouched; we extend behaviour      #
#           purely through the seams offered by Ruby's open classes and         #
#           dependency-injection.                                              #
#   • LSP – Test doubles (Player, Manager) honour the public contracts          #
#           required by CommandHandler collaborators.                           #
#   • ISP – Doubles expose *only* the small surface actually exercised.        #
#   • DIP – The concrete `$manager` global is replaced with an abstract stub    #
#           adhering to the expected `#submit_action` interface.               #
################################################################################

require 'test/unit/assertions'
require 'set'
require 'aethyr/core/registry'

World(Test::Unit::Assertions)

###############################################################################
# Harness shared between scenarios                                            #
###############################################################################
module CommandHandlerWorld
  # @!attribute [rw] player
  #   @return [Player] stubbed player instance used for the scenario
  # @!attribute [rw] handler_class
  #   @return [Class] concrete handler class under test
  # @!attribute [rw] handler
  #   @return [Object] instantiated handler instance
  # @!attribute [rw] captured_actions
  #   @return [Array] list of actions submitted to the stubbed manager
  attr_accessor :player, :handler_class, :handler, :captured_actions
end
World(CommandHandlerWorld)

###############################################################################
# Lightweight replacement for the global `$manager` used by the production     #
# system. It simply records every action passed to `#submit_action` so that    #
# assertions can be performed later on if needed.                              #
###############################################################################
class StubManager
  attr_reader :actions

  def initialize
    @actions = []
  end

  # Mirrors the method expected by the handlers.                               #
  def submit_action(action)
    @actions << action
  end
end

###############################################################################
# Helper – Resolve an identifier like "look" into the actual concrete handler #
# class (e.g. Aethyr::Core::Commands::Look::LookHandler).                      #
#                                                                              #
# @param identifier [String] the leaf filename without extension              #
# @return [Class] concrete handler class                                       #
###############################################################################
# rubocop:disable Metrics/MethodLength
# rubocop:disable Metrics/AbcSize
# rubocop:disable Metrics/CyclomaticComplexity
# rubocop:disable Metrics/PerceivedComplexity
# These RuboCop directives are necessary because the method purposefully
# contains several branches to locate the correct class without relying on
# ActiveSupport's constantize helper (which would introduce an additional
# dependency).
# rubocop:enable Metrics/*
###############################################################################

def resolve_handler_class(identifier)
  # ---------------------------------------------------------------------
  # Resolve the *source path* for the handler. Concrete command handlers  
  # live in two different namespaces:                                     
  #                                                                       
  #   1. lib/aethyr/core/input_handlers/<identifier>.rb                   
  #   2. lib/aethyr/core/input_handlers/admin/<identifier>.rb             
  #                                                                       
  # The second location contains admin-only commands which still obey the 
  # *exact* same runtime contract. We therefore have to attempt loading   
  # from both places.                                                     
  # ---------------------------------------------------------------------

  begin
    require "aethyr/core/input_handlers/#{identifier}"
  rescue LoadError => _e
    # Fall back to the admin collection.                                  
    begin
      require "aethyr/core/input_handlers/admin/#{identifier}"
    rescue LoadError
      # Re-raise the original error so callers receive a helpful message. 
      raise
    end
  end

  #   1. Ask the registry – preferred because it contains the fully qualified  #
  #      constants regardless of the nesting module hierarchy.                 #
  candidate = Aethyr::Extend::HandlerRegistry.get_handlers.find do |klass|
    klass.name.split('::').last.downcase == "#{identifier}handler"
  end
  return candidate if candidate

  #   2. Fallback – brute-force search through ObjectSpace for good measure.    #
  ObjectSpace.each_object(Class) do |klass|
    next unless klass < Aethyr::Extend::CommandHandler
    return klass if klass.name && klass.name.split('::').last.downcase == "#{identifier}handler"
  end

  raise "Unable to locate concrete handler class for identifier '#{identifier}'"
end

###############################################################################
# Given-steps                                                                  #
###############################################################################
Given('an isolated CommandHandler test harness') do
  # -------------------------------------------------------------------------
  # Define a *minimal* Player surrogate that fulfils the expectations found   #
  # inside CommandHandler.object_added as well as various individual handler  #
  # implementations. We only add the members actually referenced by the       #
  # production code so as to keep the doubles honest (ISP & LSP).             #
  # -------------------------------------------------------------------------
  unless defined?(::Player)
    class ::Player; end
  end

  # Provide accessor for the handler subscription performed via #subscribe.   #
  class ::Player
    attr_accessor :admin, :subscribed_handler
  end

  # Inject a stubbed "help library" supporting the sole method invoked via    #
  # the HandleHelp mixin.                                                     #
  class HelpLibraryStub
    def entry_register(_entry); end
    def topics; []; end
    def render_topic(_topic); 'help text'; end
  end

  self.player = ::Player.new
  # Grant admin privileges unconditionally – regular handlers simply ignore   #
  # the flag whereas Aethyr::Extend::AdminHandler subclasses *require* it.     #
  player.admin = true

  def player.help_library
    @__help_stub ||= HelpLibraryStub.new
  end

  # The production player stores the subscription via #subscribe.            #
  def player.subscribe(handler)
    self.subscribed_handler = handler
  end

  # Many handlers send user-facing feedback via Player#output. Implement a no-
  # op stub so that tests remain focused on handler *behaviour* rather than
  # rendering logic.
  def player.output(_text, _newline = true); end

  # Install the stubbed manager globally for the current scenario.            #
  $manager = StubManager.new
  self.captured_actions = $manager.actions
end

###############################################################################
# Granular contract verification steps                                         #
###############################################################################
# NOTE: The original monolithic step "the contract should hold for {string}"  #
# is now deprecated. The following steps provide fine-grained assertions which #
# are leveraged by the new Scenario Outline found in                           #
#   features/command_handlers_contract.feature                                 #
#                                                                              #
# The small steps retain *exactly* the same runtime behaviour as the previous  #
# composite step while promoting readability, debuggability, and reusability.  #
###############################################################################

# -----------------------------------------------------------------------------
# When – Resolve and instantiate a concrete CommandHandler implementation.     #
# -----------------------------------------------------------------------------
When('the handler for {string} is instantiated') do |identifier|
  # ---------------------------------------------------------------------------
  # 1) Resolve the concrete class via the same helper that powers the legacy   #
  #    step (Single Responsibility Principle – SRP).                           #
  # ---------------------------------------------------------------------------
  self.handler_class = resolve_handler_class(identifier)

  # ---------------------------------------------------------------------------
  # 2) Instantiate the handler. We pass the shared `player` double so that the #
  #    instance is ready for immediate interaction in subsequent assertions    #
  #    (Dependency Inversion Principle – DIP).                                 #
  # ---------------------------------------------------------------------------
  self.handler = handler_class.new(player)
end

# -----------------------------------------------------------------------------
# Then – Verify correct inheritance behaviour.                                 #
# -----------------------------------------------------------------------------
Then('the handler should inherit from CommandHandler') do
  assert_kind_of(
    Aethyr::Extend::CommandHandler,
    handler,
    "#{handler_class} does not inherit from CommandHandler"
  )
end

# -----------------------------------------------------------------------------
# Then – Verify that the handler advertises HandleHelp capabilities.           #
# -----------------------------------------------------------------------------
Then('the handler should advertise help capability') do
  assert_respond_to(handler, :can_help?, 'Handler is expected to respond to #can_help?')
  assert(
    handler.can_help?,
    'can_help? is expected to return true – the handler claims no help support'
  )
end

# -----------------------------------------------------------------------------
# Then – Verify that at least one textual command alias is exposed.            #
# -----------------------------------------------------------------------------
Then('the command handler should expose at least one command alias') do
  assert_respond_to(handler, :commands, 'Handler must define #commands')
  assert(
    !handler.commands.nil? && !handler.commands.empty?,
    'Handler must expose at least one textual command alias'
  )
end

# -----------------------------------------------------------------------------
# Then – Verify that `object_added` subscribes the handler with the Player.    #
# -----------------------------------------------------------------------------
Then('the handler should subscribe itself on object_added') do
  # Reset potential artefacts from previous assertions to keep each step       #
  # isolated and free of hidden ordering constraints.                          #
  player.subscribed_handler = nil

  # Trigger the lifecycle callback exactly like the production engine does.   #
  handler_class.object_added(game_object: player)

  assert_instance_of(
    handler_class,
    player.subscribed_handler,
    'object_added did not subscribe the expected handler'
  )
end

# -----------------------------------------------------------------------------
# Then – Verify that a sample input is processed without raising exceptions.   #
# -----------------------------------------------------------------------------
Then('processing a sample command should not raise an exception') do
  sample_input = handler.commands.first.to_s

  assert_nothing_raised(
    "player_input raised an exception for '#{sample_input}'"
  ) do
    handler.player_input(input: sample_input)
  end
end

###############################################################################
#                      H A N D L E R   R E G I S T R Y   S T E P S            #
###############################################################################
# The scenarios added to `command_handlers_contract.feature` exercise the
# public surface of `Aethyr::Extend::HandlerRegistry`.  The tiny additions
# below reuse the existing test-harness utilities (player, StubManager, etc.)
# while avoiding any new global state – thus maintaining isolation between
# unrelated scenarios.                                                          
###############################################################################
require 'set'
require 'aethyr/core/registry'

# Shared scratch-space for the newly introduced steps.
module RegistryWorld
  attr_accessor :dummy_handler_class, :registry_manager_stub
end
World(RegistryWorld)

# -----------------------------------------------------------------------------
# Given – reset the global registry so that each scenario starts from the same
#         pristine state.  We *intentionally* reach into the class-variable to
#         guarantee full branch-coverage of the public API (SRP lets us keep
#         this intrusive reflection inside the test-suite only).
# -----------------------------------------------------------------------------
Given('the HandlerRegistry is cleared') do
  Aethyr::Extend::HandlerRegistry.class_variable_set(:@@handlers, Set.new)
end

# -----------------------------------------------------------------------------
# Given – dynamically define a minimal concrete CommandHandler subclass so that
#         we can register it without coupling the test to any production file.
# -----------------------------------------------------------------------------
Given('a dummy command handler class exists') do
  # Avoid redefining the constant when scenarios run multiple times.
  unless Object.const_defined?(:DummyContractHandler)
    Object.const_set(:DummyContractHandler, Class.new(Aethyr::Extend::CommandHandler) do
      # Provide a no-op implementation that still honours the constructor
      # signature expected by CommandHandler.
      def initialize(player, *args, **kwargs)
        super(player, [], *args, help_entries: [], **kwargs)
      end

      # Advertise a single command so that other contract checks continue to
      # pass even if this class is used elsewhere in the suite.
      def commands
        [:dummy]
      end
    end)
  end

  self.dummy_handler_class = Object.const_get(:DummyContractHandler)
end

# -----------------------------------------------------------------------------
# When – register the previously defined dummy handler through the public API.
# -----------------------------------------------------------------------------
When('I register the dummy handler') do
  Aethyr::Extend::HandlerRegistry.register_handler(dummy_handler_class)
end

# -----------------------------------------------------------------------------
# When – attempt to register the *same* handler once again.
# -----------------------------------------------------------------------------
When('I register the dummy handler again') do
  Aethyr::Extend::HandlerRegistry.register_handler(dummy_handler_class)
end

# -----------------------------------------------------------------------------
# Then – ensure the registry contains exactly one unique entry.
# -----------------------------------------------------------------------------
Then('the handler registry should contain exactly {int} handler') do |count|
  handlers = Aethyr::Extend::HandlerRegistry.get_handlers
  assert_equal(count, handlers.size, "Expected exactly #{count} handler(s) but found #{handlers.size}")
end

# -----------------------------------------------------------------------------
# When – drive the `#handle` callback using a purpose-built StubManager capable
#         of recording `#subscribe` invocations made by the registry.
# -----------------------------------------------------------------------------
When('the handler registry handles a stub manager') do
  # Lightweight stub mimicking the public #subscribe interface expected by the
  # registry whilst capturing any callback invocations for later assertions.
  class RegistryTestManager
    attr_reader :subscriptions
    def initialize
      @subscriptions = []
    end
    def subscribe(handler, on:)
      @subscriptions << [handler, on]
    end
  end

  self.registry_manager_stub = RegistryTestManager.new
  Aethyr::Extend::HandlerRegistry.handle(registry_manager_stub)
end

# -----------------------------------------------------------------------------
# Then – verify *exactly* the expected subscription has been recorded.
# -----------------------------------------------------------------------------
Then('the stub manager should have exactly {int} subscription for the dummy handler') do |count|
  subs = registry_manager_stub.subscriptions.select { |klass, _| klass == dummy_handler_class }
  assert_equal(count, subs.size,
               "Expected #{count} subscription(s) for #{dummy_handler_class} but found #{subs.size}")
end

# -----------------------------------------------------------------------------
# When – attempt to register a nil handler to exercise the guard-clause branch.
# -----------------------------------------------------------------------------
When('I attempt to register a nil handler') do
  # Capture any raised exception for later validation using the custom helper.
  @raised_exception = assert_raises(RuntimeError) do
    Aethyr::Extend::HandlerRegistry.register_handler(nil)
  end
end

# -----------------------------------------------------------------------------
# Then – leverage the helper from features/support/assertions.rb to confirm the
#         precise exception message.
# -----------------------------------------------------------------------------
Then('a RuntimeError should be raised with message {string}') do |expected_message|
  assert(@raised_exception, 'Expected an exception to have been captured')
  assert_equal(expected_message, @raised_exception.message)
end 