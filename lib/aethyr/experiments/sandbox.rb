# frozen_string_literal: true

require "concurrent"
require "securerandom"
require "aethyr/core/util/log"

module Aethyr
  module Experiments
    # ============================================================================
    #  Class: Aethyr::Experiments::Sandbox
    #
    #  Acts as a *facade & execution context* injected into user scripts.  It
    #  completely hides away the complexity of the underlying server while
    #  exposing a pleasant, expressive DSL.
    #
    #  Design patterns in play:
    #
    #     • Facade         – hides hundreds of public classes behind a handful
    #                        of intent-centric methods.
    #
    #     • Command        – user-facing #command queues work as Command objects
    #                        executed by an internal scheduler.
    #
    #     • Observer/Bus   – event listeners implemented via a small pub-sub
    #                        mechanism (Concurrent::Event).
    #
    #     • Scheduler      – small job scheduler inspired by Quartz; runs on a
    #                        single lightweight thread.
    #
    #  All public methods are documented with YARD tags so experimenters can
    #  `yardoc` their playground.
    # ============================================================================
    class Sandbox
      ##########################################################################
      # Construction & Dependency Injection
      ##########################################################################
      # @param server [Manager]  The global $manager instance (or adapter).
      # @param player [Player]   The privileged 'sandbox' player.
      # @param verbose [Boolean] Diagnostic chatter flag.
      def initialize(server:, player:, verbose: false)
        @server  = server
        @player  = player
        @verbose = verbose

        @scheduler = Concurrent::TimerTask.new(run_now: false, execution_interval: 0.1) do
          dispatch_queued_commands
        end
        @scheduler.execute
        log "Sandbox initialised."
      end

      # ------------------------------------------------------------------------
      # == Public DSL  =========================================================
      # ------------------------------------------------------------------------

      # Send an in-game command *exactly* as if the sandbox player typed it.
      #
      # @param cmd [String]     Any command recognised by Aethyr's parser.
      # @param at [Numeric]     Seconds in the future to schedule execution.
      # @return [void]
      def command(cmd, at: 0)
        id = SecureRandom.hex(4)
        log "Enqueue ‹##{id}›: #{cmd.inspect} (ETA=#{at}s)"
        command_queue << { id: id, cmd: cmd, eta: Time.now + at.to_f }
      end

      # Convenience shorthand returning underlying player reference.
      #
      # @return [Player]
      def player
        @player
      end

      # Publish a block to be executed repeatedly every +interval+ seconds.
      #
      # @param interval [Numeric]
      # @yield [Sandbox] Yields *self* to the caller's block.
      # @return [void]
      def every(interval, &block)
        raise ArgumentError, "Interval must be positive" unless interval.positive?

        schedule_recurring(interval, &block)
      end

      # Block until the command queue empties and all async jobs settle.
      #
      # @return [void]
      def wait_until_idle
        sleep 0.1 until command_queue.empty?
      end

      # ------------------------------------------------------------------------
      # == Introspection & Utilities ===========================================
      # ------------------------------------------------------------------------

      # --------------------------------------------------------------
      # Internal logger – respects the @verbose flag but routes
      # messages through the central logging facility.
      # --------------------------------------------------------------
      def log(msg)
        return unless @verbose

        # Leverage Object#log for consistent formatting.
        super(msg, Logger::Ultimate)
      end

      private

      ##########################################################################
      # Command-Scheduling Infrastructure
      ##########################################################################
      def command_queue
        @command_queue ||= []
      end

      # Called by Concurrent::TimerTask ~10× per second.
      def dispatch_queued_commands
        now = Time.now
        due, later = command_queue.partition { |h| h[:eta] <= now }
        @command_queue = later

        due.each { |h| execute_command(h) }
      end

      def execute_command(h)
        log "Execute ‹##{h[:id]}› → #{h[:cmd]}"
        # NOTE: The public Aethyr API exposes CommandParser at global scope.
        parser = Object.const_get("CommandParser")
        result = parser.parse(@player, h[:cmd])
        @player.alert(result) if result
      rescue StandardError => e
        log "Command ##{h[:id]} failed: #{e.class} – #{e.message}"
      end

      ##########################################################################
      # Recurring Task Support
      ##########################################################################
      def schedule_recurring(interval, &block)
        task = Concurrent::TimerTask.new(execution_interval: interval, timeout_interval: interval) do
          block.call(self)
        rescue StandardError => e
          log "Recurring task error: #{e.class} – #{e.message}"
        end
        task.execute
      end
    end
  end
end 