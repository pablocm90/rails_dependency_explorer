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

      def format_with_architectural_analysis(graph_data, architectural_analysis: {})
        edges = graph_data[:edges]
        self.class.format_as_dot_with_architectural_analysis(edges, architectural_analysis)
      end

      def self.format_as_dot(edges)
        dot_content = edges.map { |edge| "  \"#{edge[0]}\" -> \"#{edge[1]}\";" }.join("\n")
        "digraph dependencies {\n#{dot_content}\n}"
      end

      def self.format_as_dot_with_architectural_analysis(edges, architectural_analysis)
        dot_content = ["digraph dependencies {"]
        dot_content << "  rankdir=LR;"
        dot_content << "  node [shape=box];"
        dot_content << ""

        # Add regular edges
        cross_namespace_cycle_edges = extract_cross_namespace_cycle_edges(architectural_analysis)

        edges.each do |edge|
          if cross_namespace_cycle_edges.include?(edge)
            dot_content << "  \"#{edge[0]}\" -> \"#{edge[1]}\" [color=\"red\", style=\"bold\", label=\"cross-namespace cycle\"];"
          else
            dot_content << "  \"#{edge[0]}\" -> \"#{edge[1]}\";"
          end
        end

        # Add architectural legend if there are architectural concerns
        if architectural_analysis[:cross_namespace_cycles]&.any?
          add_architectural_legend(dot_content, architectural_analysis)
        end

        dot_content << "}"
        dot_content.join("\n")
      end

      def self.extract_cross_namespace_cycle_edges(architectural_analysis)
        edges = []
        return edges unless architectural_analysis[:cross_namespace_cycles]

        architectural_analysis[:cross_namespace_cycles].each do |cycle_info|
          cycle = cycle_info[:cycle]
          (0...cycle.length - 1).each do |i|
            edges << [cycle[i], cycle[i + 1]]
          end
        end
        edges
      end

      def self.add_architectural_legend(dot_content, architectural_analysis)
        dot_content << ""
        dot_content << "  subgraph cluster_legend {"
        dot_content << "    label=\"Legend\";"
        dot_content << "    style=\"dashed\";"
        dot_content << "    color=\"gray\";"

        if architectural_analysis[:cross_namespace_cycles]&.any?
          dot_content << "    legend_cycle [label=\"Cross-Namespace Cycle\", color=\"red\", style=\"bold\"];"
        end

        dot_content << "  }"
      end
    end
  end
end
