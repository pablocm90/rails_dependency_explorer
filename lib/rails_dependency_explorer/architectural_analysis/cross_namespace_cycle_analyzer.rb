# frozen_string_literal: true

require_relative "../analysis/circular_dependency_analyzer"
require_relative "cross_namespace_cycle_filter"
require_relative "architectural_cycle_formatter"

module RailsDependencyExplorer
  # ArchitecturalAnalysis module provides advanced architectural analysis capabilities.
  # Focuses on detecting architectural problems like cross-namespace cycles, coupling issues,
  # and design pattern violations that indicate structural problems in the codebase.
  module ArchitecturalAnalysis
    # Detects circular dependencies that cross namespace boundaries.
    # Cross-namespace cycles indicate architectural problems where different
    # modules/namespaces are tightly coupled, violating separation of concerns.
    class CrossNamespaceCycleAnalyzer
      def initialize(dependency_data, circular_analyzer: nil)
        @dependency_data = dependency_data
        @injected_circular_analyzer = validate_circular_analyzer(circular_analyzer)
      end

      # Factory method for creating CrossNamespaceCycleAnalyzer with default circular analyzer
      # @param dependency_data [Hash] The dependency data to analyze
      # @param container [DependencyContainer] Optional DI container for custom circular analyzer
      # @return [CrossNamespaceCycleAnalyzer] New instance with appropriate circular analyzer
      def self.create(dependency_data, container: nil)
        if container && container.registered?(:circular_analyzer)
          circular_analyzer = container.resolve(:circular_analyzer, dependency_data)
          new(dependency_data, circular_analyzer: circular_analyzer)
        else
          new(dependency_data)
        end
      end

      def find_cross_namespace_cycles
        all_cycles = find_all_cycles
        cross_namespace_cycles = CrossNamespaceCycleFilter.cross_namespace_cycles_only(all_cycles)
        ArchitecturalCycleFormatter.format_cycles(cross_namespace_cycles)
      end

      # Pipeline integration - specify the key for pipeline results
      def analyzer_key
        :cross_namespace_cycles
      end

      # Pipeline integration - implement analyze method for BaseAnalyzer compatibility
      def analyze(dependency_data = nil)
        find_cross_namespace_cycles
      end

      private

      def find_all_cycles
        circular_analyzer.find_cycles
      end

      def circular_analyzer
        @circular_analyzer ||= @injected_circular_analyzer || RailsDependencyExplorer::Analysis::CircularDependencyAnalyzer.new(@dependency_data)
      end

      # Validate injected circular analyzer
      def validate_circular_analyzer(analyzer)
        return nil if analyzer.nil?

        unless analyzer.respond_to?(:find_cycles)
          raise ArgumentError, "Invalid circular analyzer: must respond to #find_cycles"
        end

        analyzer
      end
    end
  end
end
