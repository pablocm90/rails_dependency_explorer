# frozen_string_literal: true

module RailsDependencyExplorer
  module Analysis
    # Interface for analyzers that detect circular dependencies.
    # Defines the contract for cycle detection functionality.
    # Part of Phase 1.2 interface extraction (Tidy First - Structural).
    module CycleDetectionInterface
      # Finds circular dependencies in the dependency graph.
      # @return [Array] Array of detected cycles
      def find_cycles
        raise NotImplementedError, "#{self.class} must implement #find_cycles"
      end
    end
  end
end
