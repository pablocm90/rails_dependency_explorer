# frozen_string_literal: true

require_relative "namespace_extractor"

module RailsDependencyExplorer
  module ArchitecturalAnalysis
    # Filters cycles to identify those that cross namespace boundaries.
    # Cross-namespace cycles indicate architectural problems where different
    # modules are tightly coupled, violating separation of concerns.
    class CrossNamespaceCycleFilter
      def self.cross_namespace_cycles_only(cycles)
        cycles.select { |cycle| cross_namespace_cycle?(cycle) }
      end

      def self.cross_namespace_cycle?(cycle)
        namespaces = NamespaceExtractor.extract_namespaces_from_cycle(cycle)
        namespaces.length > 1
      end
    end
  end
end
