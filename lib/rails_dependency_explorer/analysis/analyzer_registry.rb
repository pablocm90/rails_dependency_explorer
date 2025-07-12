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
    end
  end
end
