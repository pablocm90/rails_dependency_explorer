# frozen_string_literal: true

module RailsDependencyExplorer
  module Analysis
    # Registry for managing analyzer registration and discovery.
    # Provides pluggable analyzer system for pipeline architecture.
    # Part of Phase 3.1 pipeline architecture implementation.
    class AnalyzerRegistry
      class AnalyzerNotFoundError < StandardError; end

      def initialize
        @analyzers = {}
        @metadata = {}
      end

      # Register an analyzer class or block
      def register(key, analyzer_class = nil, metadata: {}, &block)
        if block_given?
          @analyzers[key] = block
        else
          @analyzers[key] = analyzer_class
        end
        @metadata[key] = metadata
      end

      # Check if analyzer is registered
      def registered?(key)
        @analyzers.key?(key)
      end

      # Get analyzer class
      def get_analyzer_class(key)
        raise AnalyzerNotFoundError, "Analyzer '#{key}' not found" unless registered?(key)
        
        analyzer = @analyzers[key]
        return analyzer unless analyzer.is_a?(Proc)
        
        raise AnalyzerNotFoundError, "Analyzer '#{key}' is registered as block, use create_analyzer instead"
      end

      # Create analyzer instance
      def create_analyzer(key, **params)
        raise AnalyzerNotFoundError, "Analyzer '#{key}' not found" unless registered?(key)
        
        analyzer = @analyzers[key]
        
        if analyzer.is_a?(Proc)
          analyzer.call(params)
        else
          if params.empty?
            analyzer.new
          else
            analyzer.new(**params)
          end
        end
      end

      # List all registered analyzer keys
      def list_registered
        @analyzers.keys
      end

      # Unregister analyzer
      def unregister(key)
        @analyzers.delete(key)
        @metadata.delete(key)
      end

      # Clear all registered analyzers
      def clear
        @analyzers.clear
        @metadata.clear
      end

      # Get analyzer metadata
      def get_analyzer_metadata(key)
        @metadata[key] || {}
      end

      # Register analyzer if class is available
      def register_if_available(key, analyzer_class, metadata: {})
        if analyzer_class.is_a?(String)
          # Try to constantize string class name
          begin
            analyzer_class = Object.const_get(analyzer_class)
          rescue NameError
            return false
          end
        end
        
        register(key, analyzer_class, metadata: metadata)
        true
      end

      # Create a new registry with only analyzers enabled by configuration
      def create_configured_registry(configuration)
        configured_registry = self.class.new

        # Apply configuration logic to registry analyzers
        registry_analyzers = list_registered

        registry_analyzers.each do |key|
          if should_include_analyzer?(key, configuration)
            analyzer_class = @analyzers[key]
            original_metadata = get_analyzer_metadata(key)
            configured_registry.register(key, analyzer_class, metadata: original_metadata)
          end
        end

        configured_registry
      end

      # Create registry with default analyzers
      def self.create_with_defaults
        registry = new

        # Register default analyzers if available
        registry.register_if_available(:statistics, "RailsDependencyExplorer::Analysis::StatisticsAnalyzer")
        registry.register_if_available(:circular_dependencies, "RailsDependencyExplorer::Analysis::CircularDependencyAnalyzer")
        registry.register_if_available(:dependency_depth, "RailsDependencyExplorer::Analysis::DependencyDepthAnalyzer")
        registry.register_if_available(:rails_components, "RailsDependencyExplorer::Analysis::RailsComponentAnalyzer")

        registry
      end

      private

      # Determine if analyzer should be included based on configuration
      def should_include_analyzer?(key, configuration)
        return false unless analyzer_enabled_by_specific_rules?(key, configuration)
        return false unless analyzer_enabled_by_category_rules?(key, configuration)

        true
      end

      # Check if analyzer is enabled by specific analyzer rules
      def analyzer_enabled_by_specific_rules?(key, configuration)
        # Use configuration's public interface instead of accessing private state
        configuration.analyzer_enabled?(key)
      end

      # Check if analyzer is enabled by category rules
      def analyzer_enabled_by_category_rules?(key, configuration)
        metadata = get_analyzer_metadata(key)
        category = metadata[:category]

        # If no category, assume enabled
        return true unless category

        # Use configuration's public interface for category checking
        # For now, we'll assume enabled since we don't have a public category API
        # This could be improved by adding category_enabled? method to configuration
        true
      end
    end
  end
end
