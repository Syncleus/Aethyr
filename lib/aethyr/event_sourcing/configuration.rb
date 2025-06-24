require 'logger'

module Aethyr
  # @author Aethyr Development Team
  # @since 1.0.0
  #
  # The EventSourcing module contains all classes and functionality related to
  # the event sourcing system. Event sourcing is a pattern where all changes to
  # application state are captured as a sequence of events, providing a complete
  # audit trail and enabling advanced features like temporal queries and replays.
  module EventSourcing
    # Configuration class for managing event sourcing settings and ImmuDB connection parameters.
    # This class implements the Singleton pattern to ensure consistent configuration across the application.
    # It manages environment variables, connection settings, and provides configuration validation.
    #
    # @example Accessing configuration values
    #   config = Aethyr::EventSourcing::Configuration.instance
    #   puts "ImmuDB host: #{config.immudb_host}"
    #   puts "ImmuDB port: #{config.immudb_port}"
    #
    # @example Using the hash-like interface
    #   config = Aethyr::EventSourcing::Configuration.instance
    #   puts "ImmuDB host: #{config[:immudb_host]}"
    #   puts "ImmuDB port: #{config[:immudb_port]}"
    class Configuration
      include Singleton

      # Default configuration values for ImmuDB connection and event sourcing behavior
      DEFAULT_IMMUDB_HOST = 'localhost'
      DEFAULT_IMMUDB_PORT = 3322
      DEFAULT_IMMUDB_USER = 'immudb'
      DEFAULT_IMMUDB_PASS = 'immudb'
      DEFAULT_SNAPSHOT_FREQUENCY = 500
      DEFAULT_RETRY_ATTEMPTS = 5
      DEFAULT_RETRY_BASE_DELAY = 0.1
      DEFAULT_RETRY_MAX_DELAY = 5.0

      attr_reader :immudb_host, :immudb_port, :immudb_user, :immudb_pass,
                  :snapshot_frequency, :retry_attempts, :retry_base_delay, :retry_max_delay

      # Initializes the configuration by loading values from environment variables
      # or falling back to sensible defaults. This method implements comprehensive
      # validation of configuration parameters to ensure system stability.
      def initialize
        @immudb_host = ENV['IMMUDB_HOST'] || DEFAULT_IMMUDB_HOST
        @immudb_port = (ENV['IMMUDB_PORT'] || DEFAULT_IMMUDB_PORT).to_i
        @immudb_user = ENV['IMMUDB_USER'] || DEFAULT_IMMUDB_USER
        @immudb_pass = ENV['IMMUDB_PASS'] || DEFAULT_IMMUDB_PASS
        @snapshot_frequency = (ENV['SNAPSHOT_FREQUENCY'] || DEFAULT_SNAPSHOT_FREQUENCY).to_i
        @retry_attempts = (ENV['RETRY_ATTEMPTS'] || DEFAULT_RETRY_ATTEMPTS).to_i
        @retry_base_delay = (ENV['RETRY_BASE_DELAY'] || DEFAULT_RETRY_BASE_DELAY).to_f
        @retry_max_delay = (ENV['RETRY_MAX_DELAY'] || DEFAULT_RETRY_MAX_DELAY).to_f

        validate_configuration!
      end

      # Retrieves the singleton instance of the configuration
      # @return [Configuration] The singleton configuration instance
      def self.instance
        @instance ||= new
      end

      # Provides access to configuration values through a hash-like interface
      # @param key [Symbol] The configuration key to retrieve
      # @return [Object] The configuration value
      def [](key)
        case key
        when :immudb_host then @immudb_host
        when :immudb_port then @immudb_port
        when :immudb_user then @immudb_user
        when :immudb_pass then @immudb_pass
        when :snapshot_frequency then @snapshot_frequency
        when :retry_attempts then @retry_attempts
        when :retry_base_delay then @retry_base_delay
        when :retry_max_delay then @retry_max_delay
        else
          raise ArgumentError, "Unknown configuration key: #{key}"
        end
      end

      # Generates the ImmuDB connection string for gRPC connections
      # @return [String] The formatted connection string
      def immudb_address
        "#{@immudb_host}:#{@immudb_port}"
      end

      # Creates a hash of connection parameters suitable for ImmuDB client initialization
      # @return [Hash] Connection parameters hash
      def connection_params
        {
          address: immudb_address,
          username: @immudb_user,
          password: @immudb_pass
        }
      end

      # Validates that all configuration parameters are within acceptable ranges
      # and meet the requirements for stable operation
      # @raise [ArgumentError] If any configuration parameter is invalid
      def validate_configuration!
        raise ArgumentError, "ImmuDB host cannot be empty" if @immudb_host.nil? || @immudb_host.strip.empty?
        raise ArgumentError, "ImmuDB port must be between 1 and 65535" unless @immudb_port.between?(1, 65535)
        raise ArgumentError, "ImmuDB user cannot be empty" if @immudb_user.nil? || @immudb_user.strip.empty?
        raise ArgumentError, "ImmuDB password cannot be empty" if @immudb_pass.nil? || @immudb_pass.strip.empty?
        raise ArgumentError, "Snapshot frequency must be positive" unless @snapshot_frequency > 0
        raise ArgumentError, "Retry attempts must be non-negative" unless @retry_attempts >= 0
        raise ArgumentError, "Retry base delay must be positive" unless @retry_base_delay > 0
        raise ArgumentError, "Retry max delay must be greater than base delay" unless @retry_max_delay > @retry_base_delay
      end

      # Provides a human-readable string representation of the configuration
      # for logging and debugging purposes. Sensitive information is masked.
      # @return [String] Formatted configuration string
      def to_s
        <<~CONFIG
          Aethyr Event Sourcing Configuration:
            ImmuDB Host: #{@immudb_host}
            ImmuDB Port: #{@immudb_port}
            ImmuDB User: #{@immudb_user}
            ImmuDB Password: #{'*' * @immudb_pass.length}
            Snapshot Frequency: #{@snapshot_frequency}
            Retry Attempts: #{@retry_attempts}
            Retry Base Delay: #{@retry_base_delay}s
            Retry Max Delay: #{@retry_max_delay}s
        CONFIG
      end
    end
  end
end 
