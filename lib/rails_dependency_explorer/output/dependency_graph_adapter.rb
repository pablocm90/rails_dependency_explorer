# frozen_string_literal: true

require "set"

module RailsDependencyExplorer
  module Output
    # Transforms dependency analysis results into graph data structures.
    # Converts raw dependency information into nodes and edges format suitable
    # for visualization libraries and graph-based analysis tools.
    class DependencyGraphAdapter
      def to_graph(dependency_data)
        nodes = extract_nodes(dependency_data)
        edges = extract_edges(dependency_data)

        {
          nodes: nodes.to_a,
          edges: edges.to_a
        }
      end

      def self.add_dependent_nodes(nodes, dependencies)
        dependencies.each do |dependency_hash|
          dependency_hash.each_key { |dependent_class| nodes.add(dependent_class) }
        end
      end

      def self.add_edges_for_class(edges, class_name, dependencies)
        dependencies.each do |dependency_hash|
          dependency_hash.each_key { |dependent_class| edges.add([class_name, dependent_class]) }
        end
      end

      private

      def extract_nodes(dependency_data)
        nodes = Set.new

        dependency_data.each do |class_name, dependencies|
          nodes.add(class_name)
          add_dependent_nodes(nodes, dependencies)
        end

        nodes
      end

      def add_dependent_nodes(nodes, dependencies)
        self.class.add_dependent_nodes(nodes, dependencies)
      end

      def extract_edges(dependency_data)
        edges = Set.new

        dependency_data.each do |class_name, dependencies|
          add_edges_for_class(edges, class_name, dependencies)
        end

        edges
      end

      def add_edges_for_class(edges, class_name, dependencies)
        self.class.add_edges_for_class(edges, class_name, dependencies)
      end
    end
  end
end
