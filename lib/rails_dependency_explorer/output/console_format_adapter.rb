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
        output = build_header_lines(nodes)
        add_dependency_lines(output, edges)
        output
      end

      def self.build_header_lines(nodes)
        output = build_title_section
        add_classes_section(output, nodes)
        add_dependencies_header(output)
        output
      end

      def self.build_title_section
        ["Dependencies found:", ""]
      end

      def self.add_classes_section(output, nodes)
        output << "Classes: #{nodes.join(", ")}"
        output << ""
      end

      def self.add_dependencies_header(output)
        output << "Dependencies:"
      end

      def self.add_dependency_lines(output, edges)
        edges.each do |from, to|
          output << "  #{from} -> #{to}"
        end
      end
    end
  end
end
