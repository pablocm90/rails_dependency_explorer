# frozen_string_literal: true

module RailsDependencyExplorer
  module Output
    # Base class for output formatting strategies.
    # Implements the Strategy pattern to reduce method proliferation in DependencyVisualizer.
    # Each concrete strategy handles a specific output format (JSON, HTML, DOT, CSV, etc.).
    # Part of Phase 4.1 output strategy hierarchy (Tidy First - Structural changes).
    class OutputStrategy
      # Format dependency data into the strategy's specific output format.
      # @param dependency_data [Hash] The dependency data to format
      # @param statistics [Hash] Optional statistics data
      # @param architectural_analysis [Hash] Optional architectural analysis data
      # @return [String] Formatted output in the strategy's format
      def format(dependency_data, statistics = nil, architectural_analysis: {})
        raise NotImplementedError, "#{self.class} must implement #format"
      end

      # Check if this strategy supports architectural analysis enhancement
      # @return [Boolean] true if strategy supports architectural analysis
      def supports_architectural_analysis?
        true
      end

      protected

      # Helper method to check if architectural analysis data is present
      # @param architectural_analysis [Hash] Architectural analysis data
      # @return [Boolean] true if architectural analysis data is present
      def has_architectural_analysis?(architectural_analysis)
        architectural_analysis && !architectural_analysis.empty?
      end
    end
  end
end
