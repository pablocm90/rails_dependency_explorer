# frozen_string_literal: true

module RailsDependencyExplorer
  # Output module handles formatting and visualization of dependency analysis results.
  # Provides multiple format adapters for different output types including console, DOT graphs,
  # JSON, HTML, and CSV formats. Separates output formatting concerns from analysis logic.
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

      def self.format_architectural_analysis(architectural_data)
        output = []

        if architectural_data[:cross_namespace_cycles]
          output << format_cross_namespace_cycles(architectural_data[:cross_namespace_cycles])
        end

        output.join("\n")
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

      def self.format_cross_namespace_cycles(cycles)
        output = "Cross-Namespace Cycles:\n"

        if cycles.empty?
          output += "  ✅ None detected"
        else
          cycle_count = cycles.length
          output += "  ⚠️  HIGH SEVERITY (#{cycle_count} cycle#{'s' if cycle_count > 1} detected)\n"

          cycles.each do |cycle_info|
            output += "    #{cycle_info[:cycle].join(' -> ')}\n"
            output += "    Namespaces: #{cycle_info[:namespaces].join(', ')}\n"
          end
        end

        output
      end

      private_class_method :build_output_lines, :build_header_lines, :build_title_section, :add_classes_section, :add_dependencies_header, :add_dependency_lines, :format_cross_namespace_cycles
    end
  end
end
