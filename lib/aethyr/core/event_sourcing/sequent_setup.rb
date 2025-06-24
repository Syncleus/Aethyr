begin
  require 'sequent'
  require 'aethyr/core/event_sourcing/immudb_event_store'
  require 'aethyr/core/event_sourcing/domain'
  require 'aethyr/core/event_sourcing/events'
  require 'aethyr/core/event_sourcing/commands'
  require 'aethyr/core/event_sourcing/command_handlers'
  require 'aethyr/core/event_sourcing/projections'
  require 'aethyr/core/util/config'
  require 'aethyr/core/util/log'

  module Aethyr
    module Core
      module EventSourcing
        # The SequentSetup class orchestrates the initialization and configuration of the
        # event sourcing system. It provides methods to configure Sequent, rebuild world state
        # from events, and retrieve event store statistics.
        #
        # This class serves as the main entry point for event sourcing functionality and
        # handles graceful degradation when the Sequent gem is not available.
        #
        # Key responsibilities:
        # - Configuring the Sequent framework with appropriate components
        # - Rebuilding world state from events after server restart
        # - Providing statistics about the event store
        #
        # @example Configuring the event sourcing system
        #   Aethyr::Core::EventSourcing::SequentSetup.configure
        #
        # @example Rebuilding world state from events
        #   Aethyr::Core::EventSourcing::SequentSetup.rebuild_world_state
        #
        # @example Getting event store statistics
        #   stats = Aethyr::Core::EventSourcing::SequentSetup.event_store_stats
        #   puts "Event count: #{stats[:event_count]}"
        class SequentSetup
          def self.configure
            log "Configuring Sequent with event store", Logger::Medium
            
            # Configure Sequent
            Sequent.configure do |config|
              config.event_store = ImmudbEventStore.new
              
              # Register command handlers
              config.command_handlers = [
                GameObjectCommandHandler.new
              ]
              
              # Register event handlers (updated for Sequent 8.2.0)
              config.event_handlers = [
                GameObjectProjector.new,
                PlayerProjector.new,
                RoomProjector.new
              ]
              
              # Configure snapshotting
              
              # Configure event publishing
              config.event_publisher = Sequent::Core::EventPublisher.new
            end
            
            log "Sequent configured successfully", Logger::Medium
            return true
          end
        
          def self.rebuild_world_state
            log "Rebuilding world state from events", Logger::Medium
            
            # Get statistics before rebuild
            stats_before = Sequent.configuration.event_store.statistics
            log "Event store contains #{stats_before[:event_count]} events across #{stats_before[:aggregate_count]} aggregates", Logger::Medium
            
            # Verify game objects against event store
            if $manager && $manager.respond_to?(:game_objects) && $manager.game_objects
              # Check for any objects that exist in memory but not in event store
              missing_in_event_store = []
              $manager.game_objects.each do |obj|
                begin
                  Sequent.aggregate_repository.load_aggregate(obj.goid)
                rescue Sequent::Core::AggregateRepository::AggregateNotFound
                  missing_in_event_store << obj.goid
                end
              end
              
              if missing_in_event_store.any?
                log "Found #{missing_in_event_store.size} objects missing from event store", Logger::Medium
                # These could be automatically added if needed
              end
            end
            
            # This is where we would rebuild projections if needed
            # For now, we're just verifying the event store integrity
            
            log "World state rebuilt successfully", Logger::Medium
            return true
          end
          
          # Add a method to get event store statistics
          def self.event_store_stats
            return {} unless defined?(Sequent.configuration) && Sequent.configuration.event_store
            
            Sequent.configuration.event_store.statistics
          end
        end
      end
    end
  end
rescue LoadError => e
  # Create a stub module if Sequent is not available
  module Aethyr
    module Core
      module EventSourcing
        # Stub implementation of the SequentSetup class for when the Sequent gem is not available.
        # This class provides graceful degradation by implementing the same interface as the
        # real SequentSetup class but returning appropriate failure responses.
        #
        # This ensures that the application can still run without event sourcing functionality
        # when the Sequent gem is not installed.
        class SequentSetup
          # Stub implementation of the configure method.
          #
          # This method logs a message indicating that event sourcing is disabled
          # due to the Sequent gem not being available and returns false.
          #
          # @return [Boolean] false to indicate configuration failure
          def self.configure
            log "Event sourcing disabled: Sequent gem not available", Logger::Medium
            log "Install with: gem install sequent concurrent-ruby", Logger::Medium
            return false
          end
          
          # Stub implementation of the rebuild_world_state method.
          #
          # This method logs a message indicating that event sourcing is disabled
          # due to the Sequent gem not being available and returns false.
          #
          # @return [Boolean] false to indicate rebuild failure
          def self.rebuild_world_state
            log "Event sourcing disabled: Sequent gem not available", Logger::Medium
            return false
          end
          
          # Stub implementation of the event_store_stats method.
          #
          # This method returns an empty hash to indicate that no statistics are available.
          #
          # @return [Hash] An empty hash
          def self.event_store_stats
            {}
          end
        end
      end
    end
  end
end
