# frozen_string_literal: true

module RailsDependencyExplorer
  module Output
    # Formats dependency analysis results into DOT graph format.
    # Generates Graphviz-compatible DOT notation for creating visual dependency graphs
    # that can be rendered by graph visualization tools like Graphviz.
    class DotFormatAdapter
      def format(graph_data)
        edges = graph_data[:edges]
        self.class.format_as_dot(edges)
      end

      private

      def self.format_as_dot(edges)
        dot_content = edges.map { |edge| "  \"#{edge[0]}\" -> \"#{edge[1]}\";" }.join("\n")
        "digraph dependencies {\n#{dot_content}\n}"
      end
    end
  end
end
