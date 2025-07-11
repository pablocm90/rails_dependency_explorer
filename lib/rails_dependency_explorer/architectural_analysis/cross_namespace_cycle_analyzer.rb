# frozen_string_literal: true

require_relative "../analysis/circular_dependency_analyzer"
require_relative "cross_namespace_cycle_filter"
require_relative "architectural_cycle_formatter"

module RailsDependencyExplorer
  module ArchitecturalAnalysis
    # Detects circular dependencies that cross namespace boundaries.
    # Cross-namespace cycles indicate architectural problems where different
    # modules/namespaces are tightly coupled, violating separation of concerns.
    class CrossNamespaceCycleAnalyzer
      def initialize(dependency_data)
        @dependency_data = dependency_data
      end

      def find_cross_namespace_cycles
        all_cycles = find_all_cycles
        cross_namespace_cycles = CrossNamespaceCycleFilter.cross_namespace_cycles_only(all_cycles)
        ArchitecturalCycleFormatter.format_cycles(cross_namespace_cycles)
      end

      private

      def find_all_cycles
        circular_analyzer = RailsDependencyExplorer::Analysis::CircularDependencyAnalyzer.new(@dependency_data)
        circular_analyzer.find_cycles
      end


    end
  end
end
