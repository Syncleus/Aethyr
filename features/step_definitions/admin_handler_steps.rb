# features/step_definitions/admin_handler_steps.rb
# frozen_string_literal: true
################################################################################
# Contract-validation steps for any concrete subclass of                      #
#   Aethyr::Extend::AdminHandler                                              #
#                                                                              #
# Design‐wise this file is intentionally crafted around the SOLID axioms:      #
#                                                                              #
#   • SRP – Every logical assertion resides in its own well-named section.     #
#   • OCP – The production code remains *closed* to modification. We extend     #
#           behaviour purely through test-side composition and dependency       #
#           substitution.                                                      #
#   • LSP – All doubles (Player, Manager) honour the *observable* contracts     #
#           required by the handlers thus ensuring valid behavioural sub-typing.#
#   • ISP – The doubles purposefully expose only the micro-surface that is      #
#           exercised by the handler code path.                                 #
#   • DIP – We invert control of the global `$manager` dependency by injecting  #
#           a minimal stub implementing the required `#submit_action` API.      #
################################################################################

require 'test/unit/assertions'
require 'set'
require 'aethyr/core/registry'

# Mixin Test::Unit assertions directly into the Cucumber execution context.    #
World(Test::Unit::Assertions)

###############################################################################
# World – scenario-specific state container                                     #
###############################################################################
module AdminHandlerWorld
  # @!attribute [rw] player_admin
  #   @return [Player] stub endowed with administrator rights
  # @!attribute [rw] player_regular
  #   @return [Player] stub **without** administrator rights
  # @!attribute [rw] handler_class
  #   @return [Class] concrete handler class under inspection
  # @!attribute [rw] handler
  #   @return [Object] instance of the concrete handler bound to +player_admin+
  # @!attribute [rw] captured_actions
  #   @return [Array] actions recorded by the stubbed manager instance
  attr_accessor :player_admin, :player_regular, :handler_class, :handler, :captured_actions
end
World(AdminHandlerWorld)

###############################################################################
# StubManager – drop-in replacement for the global `$manager` collaborator.     #
# It merely records all actions so that caller scenarios can assert against     #
# the *side-effects* without interacting with the full game engine.            #
###############################################################################
unless defined?(StubManager)
  class StubManager
    attr_reader :actions

    def initialize
      @actions = []
    end

    # Mirror of the public interface expected by production handlers.
    #
    # @param action [Object] arbitrary command object produced by the handler
    #   under test.
    # @return [void]
    def submit_action(action)
      @actions << action
    end
  end
end

###############################################################################
# Helper – Resolve a textual identifier (e.g. "aset") into its corresponding   #
# concrete handler class. Prefer the generic helper from the command handler   #
# suite if present in the runtime; otherwise fall back to a minimal inline     #
# implementation.                                                             #
###############################################################################

def resolve_admin_handler_class(identifier)
  # -----------------------------------------------------------------------
  # 1) Delegate whenever the generic helper is available. This avoids code  #
  #    duplication and keeps the single point of truth DRY.                 #
  # -----------------------------------------------------------------------
  if defined?(resolve_handler_class)
    # NB: Delegating to the already-defined helper keeps things DRY.
    return resolve_handler_class(identifier)
  end

  # -----------------------------------------------------------------------
  # 2) Minimal standalone resolution logic.                                  #
  # -----------------------------------------------------------------------
  begin
    require "aethyr/core/input_handlers/admin/#{identifier}"
  rescue LoadError
    raise "Unable to load AdminHandler source file for identifier '#{identifier}'"
  end

  ObjectSpace.each_object(Class) do |klass|
    next unless klass < Aethyr::Extend::AdminHandler
    return klass if klass.name && klass.name.split('::').last.downcase == "#{identifier}handler"
  end

  raise "Unable to locate concrete AdminHandler class for identifier '#{identifier}'"
end

###############################################################################
# Given-steps                                                                  #
###############################################################################
Given('an isolated AdminHandler test harness') do
  # -----------------------------------------------------------------------
  # Define – or reopen – the minimalistic Player surrogate demanded by the  #
  # production AdminHandler hierarchy. We purposefully inject *only* the     #
  # members referenced by the concrete code paths so as to keep the double   #
  # honest and aligned with the ISP principle.                               #
  # -----------------------------------------------------------------------
  unless defined?(::Player)
    class ::Player; end
  end

  class ::Player
    # Flag indicating whether the player possesses elevated admin rights.
    attr_accessor :admin
    # Stores the handler instance subscribed via #subscribe so that we can
    # validate correct behaviour inside `object_added`.
    attr_accessor :subscribed_handler
  end

  # Provide *exactly* the public API surface required by the HandleHelp mixin.
  class HelpLibraryStub
    def entry_register(_entry); end
    def topics; []; end
    def render_topic(_topic); 'help text'; end
  end

  # Instantiate both variants of the player double.
  self.player_admin   = ::Player.new
  self.player_regular = ::Player.new

  # Grant / revoke privileges.
  player_admin.admin   = true
  player_regular.admin = false

  # Stubbing application-level dependencies ---------------------------------
  # Bind a no-op help library so that Handler#can_help? passes successfully.
  [player_admin, player_regular].each do |p|
    def p.help_library
      @__help_stub ||= HelpLibraryStub.new
    end

    # Concrete handlers usually send feedback to the Player#output channel.
    def p.output(_text, _newline = true); end

    # Capture subscriptions so that we can later on assert *who* received what
    # handler instance.
    def p.subscribe(handler)
      self.subscribed_handler = handler
    end
  end

  # Replace the global game manager with a super-lightweight stub.
  $manager = StubManager.new
  self.captured_actions = $manager.actions
end

###############################################################################
# NEW – Granular step definitions *********************************************
###############################################################################

Given('the admin handler {string} class is resolved') do |identifier|
  # Locate the concrete class and cache for subsequent steps.
  self.handler_class = resolve_admin_handler_class(identifier)
end

Given('the admin handler is instantiated') do
  # Ensure the class has been resolved first.
  raise 'handler_class not set – call step to resolve the class first' unless handler_class
  self.handler = handler_class.new(player_admin)
end

Then('the handler should inherit from AdminHandler') do
  assert_kind_of(Aethyr::Extend::AdminHandler, handler,
                 "#{handler_class} does not inherit from AdminHandler")
  assert_kind_of(Aethyr::Extend::CommandHandler, handler,
                 "#{handler_class} does not inherit from CommandHandler")
end

Then('the handler should provide help capability') do
  assert_respond_to(handler, :can_help?)
  assert(handler.can_help?, 'can_help? is expected to return true')
end

Then('the handler should expose at least one command alias') do
  assert_respond_to(handler, :commands)
  assert(!handler.commands.nil? && !handler.commands.empty?,
         'Handler must expose at least one textual command alias')
end

Then('object_added should subscribe the handler for admin player') do
  player_admin.subscribed_handler = nil
  handler_class.object_added(game_object: player_admin)
  assert_instance_of(handler_class, player_admin.subscribed_handler,
                     'object_added did not subscribe the expected handler for admin player')
end

Then('object_added should not subscribe the handler for regular player') do
  player_regular.subscribed_handler = nil
  handler_class.object_added(game_object: player_regular)
  assert_nil(player_regular.subscribed_handler,
             'object_added should NOT subscribe handler instances for non-admin players')
end

Then('player_input should not raise') do
  sample_input = handler.commands.first.to_s
  assert_nothing_raised("player_input raised an exception for '#{sample_input}'") do
    handler.player_input(input: sample_input)
  end
end 