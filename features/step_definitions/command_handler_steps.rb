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
  # Force-load the source-file so that the class constant becomes defined.     #
  require "aethyr/core/input_handlers/#{identifier}"

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
# Then-steps                                                                   #
###############################################################################
Then('the contract should hold for {string}') do |identifier|
  # Resolve & instantiate the concrete handler class.                         #
  self.handler_class = resolve_handler_class(identifier)
  self.handler       = handler_class.new(player)

  # -----------------------------------------------------------------------
  # 1) Inheritance chain                                                   #
  # -----------------------------------------------------------------------
  assert_kind_of(Aethyr::Extend::CommandHandler, handler,
                 "#{handler_class} does not inherit from CommandHandler")

  # -----------------------------------------------------------------------
  # 2) HandleHelp capabilities                                             #
  # -----------------------------------------------------------------------
  assert_respond_to(handler, :can_help?)
  assert(handler.can_help?, 'can_help? is expected to return true')

  # -----------------------------------------------------------------------
  # 3) Command enumeration                                                 #
  # -----------------------------------------------------------------------
  assert_respond_to(handler, :commands)
  assert(!handler.commands.nil? && !handler.commands.empty?,
         'Handler must expose at least one textual command alias')

  # -----------------------------------------------------------------------
  # 4) object_added subscription behaviour                                 #
  # -----------------------------------------------------------------------
  # Clear any previous subscription artefacts.
  player.subscribed_handler = nil
  handler_class.object_added(game_object: player)
  assert_instance_of(handler_class, player.subscribed_handler,
                     'object_added did not subscribe the expected handler')

  # -----------------------------------------------------------------------
  # 5) player_input must not raise                                         #
  # -----------------------------------------------------------------------
  sample_input = handler.commands.first.to_s
  assert_nothing_raised("player_input raised an exception for '#{sample_input}'") do
    handler.player_input(input: sample_input)
  end
end 