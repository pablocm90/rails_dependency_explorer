# frozen_string_literal: true

module RailsDependencyExplorer
  module Output
    # Formats dependency analysis results for console/terminal display.
    # Converts graph data into human-readable text format with proper indentation
    # and structure for command-line output and debugging purposes.
    class ConsoleFormatAdapter
      def self.format(graph_data)
        nodes = graph_data[:nodes]
        return "No dependencies found." if nodes.empty?

        build_output_lines(nodes, graph_data[:edges]).join("\n")
      end

      private

      def self.build_output_lines(nodes, edges)
        output = []
        output << "Dependencies found:"
        output << ""
        output << "Classes: #{nodes.join(", ")}"
        output << ""
        output << "Dependencies:"
        edges.each do |from, to|
          output << "  #{from} -> #{to}"
        end
        output
      end
    end
  end
end
