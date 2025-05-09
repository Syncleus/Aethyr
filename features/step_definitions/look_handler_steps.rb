# features/step_definitions/look_handler_steps.rb
# frozen_string_literal: true
################################################################################
# Step-definitions validating Aethyr::Core::Commands::Look::LookHandler.        #
#                                                                              #
#  ‣ Single-Responsibility Principle – Each step performs exactly one          #
#    behavioural assertion.
#  ‣ Open/Closed Principle – The production code remains untouched; all        #
#    required seams for testing are introduced via light-weight doubles.       #
#  ‣ Liskov Substitution Principle – Test doubles honour the public contracts  #
#    expected by the LookHandler and Manager collaborators.                    #
#  ‣ Interface Segregation Principle – Doubles implement *only* the interface  #
#    actually exercised by the handler, thereby keeping the tests honest.      #
#  ‣ Dependency Inversion Principle – The concrete $manager global is replaced #
#    by a stub that conforms to the abstract «submit_action» dependency.       #
################################################################################

require 'test/unit/assertions'
require 'set'                                         # Ensures ::Set is defined
require 'aethyr/core/input_handlers/look'            # Class under test

World(Test::Unit::Assertions)

###############################################################################
# Shared state for the feature – kept deliberately tiny and intention-revealing.
###############################################################################
module LookHandlerWorld
  attr_accessor :player, :handler, :captured_actions, :help_entries
end
World(LookHandlerWorld)

###############################################################################
# Helper – Install a minimalist replacement for the global $manager so that   #
# LookHandler can operate in isolation from the full game-engine.             #
###############################################################################
class StubManager
  # Public: Capture every action submitted during the scenario run.
  attr_reader :actions

  def initialize
    @actions = []
  end

  # -------------------------------------------------------------------------
  # Emulates the asynchronous dispatch performed by the real Manager. For the
  # purposes of the unit tests we simply record the action for later
  # inspection.
  # -------------------------------------------------------------------------
  def submit_action(action)
    @actions << action
  end
end

###############################################################################
# Given-steps                                                                #
###############################################################################
Given('a stubbed LookHandler environment') do
  # -------------------------------------------------------------------------
  # Create a light-weight stand-in for Player that still satisfies the type    #
  # check performed via «is_a? Player» inside CommandHandler.object_added.     #
  # -------------------------------------------------------------------------
  unless defined?(::Player)
    # The dummy definition is only installed when the real class is absent so
    # that we do not inadvertently monkey-patch the production model class.
    class ::Player; end
  end

  # Minimal set of methods that the LookHandler or the registration callback   #
  # might invoke on the Player instance.                                       #
  @player = ::Player.new
  # -------------------------------------------------------------------------
  # Inject "HelpLibrary" stub so LookHandler's HandleHelp mixin can safely
  # register new help entries without triggering a NoMethodError.            #
  #--------------------------------------------------------------------------
  class HelpLibraryStub
    # Public: Mimics the signature of the real #entry_register but acts as a
    # no-op. This keeps the test focused on LookHandler behaviour whilst
    # satisfying the collaboration contract (Liskov Substitution Principle).
    def entry_register(_entry); end
  end

  def @player.help_library
    @help_library_stub ||= HelpLibraryStub.new
  end

  def @player.subscribe(handler)
    @subscribed_handler = handler
  end
  def @player.subscribed_handler
    @subscribed_handler
  end

  # Instantiate the handler under test.                                       #
  @handler = Aethyr::Core::Commands::Look::LookHandler.new(@player)

  # Inject our stubbed manager in place of the production global.             #
  $manager = StubManager.new

  # Track submitted actions for easy access in step-definitions.              #
  @captured_actions = $manager.actions
end

Given('a fresh stubbed Player instance') do
  # Stand-alone variant reused by the object_added scenario.
  class ::Player; end unless defined?(::Player)

  @player = ::Player.new

  # Provide stubbed #help_library for this fresh player as well.
  class HelpLibraryStub
    def entry_register(_entry); end
  end

  def @player.help_library
    @help_library_stub ||= HelpLibraryStub.new
  end

  def @player.subscribe(handler)
    @subscribed_handler = handler
  end

  def @player.subscribed_handler
    @subscribed_handler
  end
end

###############################################################################
# When-steps                                                                 #
###############################################################################
When('the player enters {string}') do |input|
  # Ensure each test starts with a clean capture array – guarantees isolation.
  @captured_actions.clear
  @handler.player_input(input: input)
end

when_object_added = 'the LookHandler receives an object_added notification for that player'
When("#{when_object_added}") do
  # Pass a data-hash that mimics the real event structure.
  Aethyr::Core::Commands::Look::LookHandler.object_added(game_object: @player)
end

When('I request the LookHandler help entries') do
  @help_entries = Aethyr::Core::Commands::Look::LookHandler.create_help_entries
end

###############################################################################
# Then-steps                                                                 #
###############################################################################
Then('the manager should receive a Look command with parameter kind {string} and value {string}') do |kind, value|
  assert(!@captured_actions.empty?, 'No actions were captured – submit_action was not invoked?')
  action = @captured_actions.last

  # Sanity check – ensure the right command type reached the manager.
  assert_instance_of(Aethyr::Core::Actions::Look::LookCommand, action,
                     "Expected a LookCommand but received #{action.class}")

  # OpenStruct provides a concise to_h for introspection.
  params = action.to_h

  case kind
  when 'none'
    assert_nil(params[:at],  'Unexpected :at parameter present')
    assert_nil(params[:in],  'Unexpected :in parameter present')
  when 'at'
    assert_equal(value, params[:at], 'Incorrect :at parameter')
    assert_nil(params[:in], 'Unexpected :in parameter present')
  when 'in'
    assert_equal(value, params[:in], 'Incorrect :in parameter')
    assert_nil(params[:at], 'Unexpected :at parameter present')
  else
    flunk("Unknown parameter kind '#{kind}' specified in feature table")
  end
end

Then('the player should have subscribed to a LookHandler instance') do
  handler = @player.subscribed_handler
  assert(handler, 'Player did not record any subscription via #subscribe')
  assert_instance_of(Aethyr::Core::Commands::Look::LookHandler, handler,
                     'Subscribed object is not a LookHandler instance')
end

Then('the result should contain exactly one entry') do
  assert_equal(1, @help_entries.size,
               "Expected exactly one HelpEntry but found #{@help_entries.size}")
  assert_instance_of(Aethyr::Core::Help::HelpEntry, @help_entries.first)
end

Then('the entry should advertise alias {string}') do |alias_name|
  entry = @help_entries.first
  assert(entry.aliases.include?(alias_name),
         "HelpEntry.aliases does not include #{alias_name.inspect}")
end

Then('the entry should list the syntax token {string}') do |syntax_token|
  entry = @help_entries.first
  assert(entry.syntax_formats.include?(syntax_token),
         "HelpEntry.syntax_formats does not include #{syntax_token.inspect}")
end 