# frozen_string_literal: true

require_relative "output_strategy"
require_relative "dot_format_adapter"
require_relative "dependency_graph_adapter"

module RailsDependencyExplorer
  module Output
    # DOT output strategy for dependency visualization.
    # Formats dependency data into DOT graph format using existing adapters.
    # Part of Phase 4.1 output strategy hierarchy implementation.
    class DotOutputStrategy < OutputStrategy
      def initialize
        @graph_adapter = DependencyGraphAdapter.new
        @dot_adapter = DotFormatAdapter.new
      end

      # Format dependency data into DOT format
      # @param dependency_data [Hash] The dependency data to format
      # @param statistics [Hash] Optional statistics data (not used for DOT format)
      # @param architectural_analysis [Hash] Optional architectural analysis data
      # @return [String] DOT formatted output
      def format(dependency_data, statistics = nil, architectural_analysis: {})
        graph = @graph_adapter.to_graph(dependency_data)
        
        if has_architectural_analysis?(architectural_analysis)
          @dot_adapter.format_with_architectural_analysis(graph, architectural_analysis: architectural_analysis)
        else
          @dot_adapter.format(graph)
        end
      end
    end
  end
end
