# frozen_string_literal: true

module RailsDependencyExplorer
  module Output
    class DotFormatAdapter
      def format(graph_data)
        edges = graph_data[:edges]
        format_as_dot(edges)
      end

      private

      def format_as_dot(edges)
        dot_content = edges.map { |edge| "  \"#{edge[0]}\" -> \"#{edge[1]}\";" }.join("\n")
        "digraph dependencies {\n#{dot_content}\n}"
      end
    end
  end
end
