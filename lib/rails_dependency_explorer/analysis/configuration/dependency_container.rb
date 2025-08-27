# frozen_string_literal: true

require "thread"

module RailsDependencyExplorer
  module Analysis
    module Configuration
      # Lightweight dependency injection container for managing analyzer services.
      # Provides service registration, lazy loading, caching, and thread-safe resolution.
      # Part of Phase 2.1 dependency injection implementation.
      class DependencyContainer
        # Custom error for unregistered services
        class ServiceNotRegisteredError < StandardError; end

        def initialize
          @services = {}
          @cache = {}
          @mutex = Mutex.new
        end

        # Register a service with a factory block
        # @param key [Symbol] Service identifier
        # @param block [Proc] Factory block that creates the service
        def register(key, &block)
          @services[key] = block
        end

        # Resolve a service, creating it if necessary
        # @param key [Symbol] Service identifier
        # @param args [Array] Arguments to pass to the factory block
        # @return [Object] The resolved service instance
        def resolve(key, *args)
          # Check if service is registered
          unless registered?(key)
            raise ServiceNotRegisteredError, "Service '#{key}' is not registered"
          end

          # Use cache key that includes arguments for proper caching
          cache_key = [key, args]

          # Thread-safe resolution with caching
          @mutex.synchronize do
            return @cache[cache_key] if @cache.key?(cache_key)

            # Create new instance
            factory = @services[key]
            instance = factory.call(*args)
            @cache[cache_key] = instance
            instance
          end
        end

        # Check if a service is registered
        # @param key [Symbol] Service identifier
        # @return [Boolean] True if service is registered
        def registered?(key)
          @services.key?(key)
        end

        # Get list of registered service keys
        # @return [Array<Symbol>] Array of registered service keys
        def registered_services
          @services.keys
        end

        # Clear the service cache
        # Forces all services to be recreated on next resolution
        def clear_cache
          @mutex.synchronize do
            @cache.clear
          end
        end

        # Clear all services and cache
        # Removes all registered services and cached instances
        def clear_all
          @mutex.synchronize do
            @services.clear
            @cache.clear
          end
        end

        # Get cache statistics for debugging
        # @return [Hash] Cache statistics including size and keys
        def cache_stats
          @mutex.synchronize do
            {
              cache_size: @cache.size,
              cached_keys: @cache.keys,
              registered_services: @services.keys
            }
          end
        end
      end
    end
  end
end
