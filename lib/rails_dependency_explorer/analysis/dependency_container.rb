# frozen_string_literal: true

require "thread"

module RailsDependencyExplorer
  module Analysis
    # Lightweight dependency injection container for managing service dependencies.
    # Provides service registration, lazy loading, caching, and thread-safe resolution.
    # Supports parameterized service creation and maintains performance characteristics.
    # Part of Phase 2.1 dependency injection implementation (TDD - Behavioral changes).
    class DependencyContainer
      # Custom error for unregistered service resolution attempts
      class ServiceNotRegisteredError < StandardError
        def initialize(service_name)
          super("Service '#{service_name}' is not registered in the container")
        end
      end

      def initialize
        @services = {}
        @cache = {}
        @mutex = Mutex.new
      end

      # Register a service with a factory block
      # @param service_name [Symbol] The name of the service
      # @param block [Proc] Factory block that creates the service instance
      def register(service_name, &block)
        raise ArgumentError, "Service name must be a symbol" unless service_name.is_a?(Symbol)
        raise ArgumentError, "Block is required for service registration" unless block_given?

        @mutex.synchronize do
          @services[service_name] = block
          # Clear all cached instances for this service (including parameterized ones)
          @cache.delete_if { |cache_key, _| cache_key.first == service_name }
        end
      end

      # Resolve a service by name with optional parameters
      # @param service_name [Symbol] The name of the service to resolve
      # @param args [Array] Arguments to pass to the service factory
      # @return [Object] The resolved service instance
      def resolve(service_name, *args)
        raise ArgumentError, "Service name must be a symbol" unless service_name.is_a?(Symbol)

        @mutex.synchronize do
          raise ServiceNotRegisteredError, service_name unless @services.key?(service_name)

          # Use cache key that includes arguments for parameterized services
          cache_key = [service_name, args]
          
          # Return cached instance if available
          return @cache[cache_key] if @cache.key?(cache_key)

          # Create new instance using factory
          factory = @services[service_name]
          instance = factory.call(*args)
          
          # Cache the instance
          @cache[cache_key] = instance
          
          instance
        end
      end

      # Get list of registered service names
      # @return [Array<Symbol>] Array of registered service names
      def registered_services
        @mutex.synchronize do
          @services.keys.dup
        end
      end

      # Clear all cached service instances
      # Services will be recreated on next resolution
      def clear_cache
        @mutex.synchronize do
          @cache.clear
        end
      end

      # Check if a service is registered
      # @param service_name [Symbol] The name of the service
      # @return [Boolean] True if service is registered
      def registered?(service_name)
        @mutex.synchronize do
          @services.key?(service_name)
        end
      end

      # Unregister a service and clear its cache
      # @param service_name [Symbol] The name of the service to unregister
      def unregister(service_name)
        @mutex.synchronize do
          @services.delete(service_name)
          # Clear all cache entries for this service (including parameterized ones)
          @cache.delete_if { |cache_key, _| cache_key.first == service_name }
        end
      end

      # Get count of registered services
      # @return [Integer] Number of registered services
      def service_count
        @mutex.synchronize do
          @services.size
        end
      end

      # Get count of cached instances
      # @return [Integer] Number of cached service instances
      def cache_size
        @mutex.synchronize do
          @cache.size
        end
      end
    end
  end
end
