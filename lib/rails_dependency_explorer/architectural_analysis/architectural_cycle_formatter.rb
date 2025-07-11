# frozen_string_literal: true

require_relative "namespace_extractor"

module RailsDependencyExplorer
  module ArchitecturalAnalysis
    # Formats cycles into structured architectural analysis results.
    # Provides consistent formatting with cycle path, namespaces, and severity.
    class ArchitecturalCycleFormatter
      def self.format_cycles(cycles, severity: "high")
        cycles.map do |cycle|
          {
            cycle: cycle,
            namespaces: NamespaceExtractor.extract_namespaces_from_cycle(cycle),
            severity: severity
          }
        end
      end

      def self.format_cycle(cycle, severity: "high")
        {
          cycle: cycle,
          namespaces: NamespaceExtractor.extract_namespaces_from_cycle(cycle),
          severity: severity
        }
      end
    end
  end
end
