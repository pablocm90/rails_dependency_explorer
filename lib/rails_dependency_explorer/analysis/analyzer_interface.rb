# frozen_string_literal: true

module RailsDependencyExplorer
  module Analysis
    # Base interface for all dependency analyzers.
    # Defines the common contract that all analyzers must implement.
    # Part of Phase 1.2 interface extraction (Tidy First - Structural).
    module AnalyzerInterface
      # Analyzes the dependency data and returns analysis results.
      # Each analyzer implementation should override this method.
      # @return [Object] Analysis results specific to the analyzer type
      def analyze
        raise NotImplementedError, "#{self.class} must implement #analyze"
      end
    end
  end
end
