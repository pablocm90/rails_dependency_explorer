# frozen_string_literal: true

module RailsDependencyExplorer
  module Output
    # Formats dependency analysis results for console/terminal display.
    # Converts graph data into human-readable text format with proper indentation
    # and structure for command-line output and debugging purposes.
    class ConsoleFormatAdapter
      def self.format(graph_data)
        nodes = graph_data[:nodes]
        if nodes.empty?
          return "No dependencies found."
        end

        output = []
        output << "Dependencies found:"
        output << ""
        output << "Classes: #{nodes.join(", ")}"
        output << ""
        output << "Dependencies:"
        graph_data[:edges].each do |from, to|
          output << "  #{from} -> #{to}"
        end

        output.join("\n")
      end
    end
  end
end
