# frozen_string_literal: true

require_relative "output_strategy"
require_relative "console_format_adapter"
require_relative "dependency_graph_adapter"

module RailsDependencyExplorer
  module Output
    # Console output strategy for dependency visualization.
    # Formats dependency data for console display using existing adapters.
    # Part of Phase 4.1 output strategy hierarchy implementation.
    class ConsoleOutputStrategy < OutputStrategy
      def initialize
        @graph_adapter = DependencyGraphAdapter.new
      end

      # Format dependency data for console output
      # @param dependency_data [Hash] The dependency data to format
      # @param statistics [Hash] Optional statistics data (not used for console format)
      # @param architectural_analysis [Hash] Optional architectural analysis data
      # @return [String] Console formatted output
      def format(dependency_data, statistics = nil, architectural_analysis: {})
        graph = @graph_adapter.to_graph(dependency_data)
        
        if has_architectural_analysis?(architectural_analysis)
          base_output = ConsoleFormatAdapter.format(graph)
          architectural_output = ConsoleFormatAdapter.format_architectural_analysis(architectural_analysis)
          "#{base_output}\n\n#{architectural_output}"
        else
          ConsoleFormatAdapter.format(graph)
        end
      end
    end
  end
end
