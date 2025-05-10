# frozen_string_literal: true

require "timeout"
require "forwardable"
require "aethyr/experiments/sandbox"
require "aethyr/core/util/log"

module Aethyr
  module Experiments
    # ----------------------------------------------------------------------------
    # Class: Aethyr::Experiments::Runner
    #
    # Orchestrates *everything* necessary to execute a user-supplied
    # experiment script in a hermetic sandbox.  Implements:
    #
    #   • Template-Method pattern – #execute is the skeleton algorithm,
    #     the details are delegated to well-named private helpers.
    #
    #   • Dependency-Inversion – depends on abstract interfaces
    #     (Sandbox, ServerAdapter) rather than concrete Aethyr classes.
    #
    #   • Open/Closed – new server adapters, schedulers, etc. can be
    #     dropped in without modifications to Runner.
    # ----------------------------------------------------------------------------
    class Runner
      extend Forwardable

      # Delegate a handful of convenience predicates to @options.
      def_delegators :@options, :verbose?, :attach?

      # Public: Construct a new runner with an OptionStruct produced by
      # CLI.  The struct must respond to +script+, +player+, +attach+,
      # and +verbose+.
      def initialize(options)
        @options = options
      end

      # Public: Entry-point – kicks off the high-level execution
      # template.  Rescues *all* StandardError descendants, prints
      # diagnostics, and exits with a non-zero status so calling
      # processes / CI pipelines fail fast.
      def execute
        validate_script_path!
        boot_or_attach_server
        bootstrap_player
        run_experiment_script
        graceful_shutdown
      rescue Interrupt
        warn "\n⇒ Interrupt caught – shutting down experiment."
        graceful_shutdown
      rescue StandardError => e
        warn format("⇒ Experiment failed: %<klass>s – %<msg>s\n\t%<backtrace>s",
                    klass: e.class, msg: e.message, backtrace: e.backtrace.first)
        graceful_shutdown(1)
      end

      private

      ####################################################################
      # 1. Pre-flight & Validation
      ####################################################################
      def validate_script_path!
        unless File.file?(@options.script)
          abort "ERROR: Script file `#{@options.script}` does not exist."
        end
      end

      ####################################################################
      # 2. Server Bootstrapping / Attachment
      ####################################################################
      def boot_or_attach_server
        log "Locating / starting Aethyr server…"

        if attach?
          attach_to_running_server
        else
          spawn_ephemeral_server
        end

        log "Server ready.  GOID count: #{$manager&.instance_variable_get(:@game_objects)&.length || 'N/A'}"
      end

      # NOTE: This is intentionally *minimal* – there are numerous ways
      # to discover a running server (UNIX sockets, DRb, REST), none of
      # which exist in core Aethyr at the moment.  We therefore duck-
      # type: we assume the host process already `require`s and
      # initialises the global `$manager`.
      def attach_to_running_server
        abort "ERROR: $manager is nil – no active server detected.  Remove --attach to auto-spawn one." unless defined?($manager) && $manager
      end

      # Spins up an in-process Aethyr server **synchronously**.
      # Implementation uses the Null-Object pattern for unsupported
      # engine features so the rest of the playground behaves.
      def spawn_ephemeral_server
        require "aethyr"

        # Attempt to reuse the shipping executable but without daemonising.
        server_launcher = File.expand_path("../../../../bin/aethyr", __dir__)

        if File.executable?(server_launcher)
          pid = spawn(server_launcher, out: File::NULL, err: File::NULL)
          @spawned_pid = pid
          log "Spawned Aethyr server (pid=#{pid}).  Waiting for boot…"

          Timeout.timeout(15) do
            sleep 0.2 until defined?($manager) && $manager
          end
        else
          warn "⚠  Unable to locate full server launcher – falling back to minimal core boot."
          require "aethyr/core/components/manager"
          $manager ||= Manager.new
        end
      rescue Timeout::Error
        abort "ERROR: Server boot timed-out.  Aborting experiment."
      end

      ####################################################################
      # 3. Player Bootstrap
      ####################################################################
      def bootstrap_player
        require "aethyr/core/objects/player" unless defined?(Player)

        @player =
          if $manager.player_exist?(@options.player)
            log "Loading existing sandbox player: #{@options.player}"
            $manager.load_player(@options.player, "")
          else
            log "Creating new sandbox player: #{@options.player}"
            # NOTE: Aethyr::Storage normally handles persistence; here
            # we punt and create an in-memory Player via Manager API.
            $manager.create_object(Player, nil, nil, nil,
                                   :@name       => @options.player,
                                   :@short_desc => "An intrepid experimenter",
                                   :@admin      => true)
          end

        # Persist the player reference into Sandbox for user scripts.
        @sandbox = Sandbox.new(server: $manager, player: @player, verbose: verbose?)
      end

      ####################################################################
      # 4. Execute User Script inside Sandbox
      ####################################################################
      def run_experiment_script
        log "Beginning experiment: #{@options.script}"
        @sandbox.instance_eval(File.read(@options.script), @options.script, 1)
        @sandbox.wait_until_idle
        log "Experiment concluded."
      end

      ####################################################################
      # 5. Teardown & Exit
      ####################################################################
      def graceful_shutdown(exit_status = 0)
        if @spawned_pid
          log "Stopping spawned server (pid=#{@spawned_pid})…"
          Process.kill("TERM", @spawned_pid)
          Process.wait(@spawned_pid)
        end
        exit exit_status
      end

      # ------------------------------------------------------------------
      # Logging helper – now routed via the global Logger.
      #
      # This method intentionally shadows the Object#log convenience
      # wrapper so that callers within Runner can remain unchanged while
      # the implementation delegates to the *real* logger.  By invoking
      # `super` we bounce up to Object#log which timestamps and formats
      # the message before passing it to `$LOG`.
      #
      # We always log at `Logger::Ultimate` severity when no explicit
      # level is provided, thereby satisfying the "Logger:Ultimate"
      # requirement.
      # ------------------------------------------------------------------
      def log(msg)
        return unless verbose?

        # Delegate to the generic Object#log implementation which is
        # defined in aethyr/core/util/log.  Using `super` keeps the call
        # stack shallow and avoids hard-coding `$LOG` usage here.
        super(msg, Logger::Ultimate)
      end
    end
  end
end 