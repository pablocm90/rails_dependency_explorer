# frozen_string_literal: true

require "set"

module RailsDependencyExplorer
  class DependencyVisualizer
    def to_graph(dependency_data)
      nodes = extract_nodes(dependency_data)
      edges = extract_edges(dependency_data)

      {
        nodes: nodes.to_a,
        edges: edges.to_a
      }
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
      dependencies.each do |dependency_hash|
        dependency_hash.each_key { |dependent_class| nodes.add(dependent_class) }
      end
    end

    def extract_edges(dependency_data)
      edges = Set.new

      dependency_data.each do |class_name, dependencies|
        add_edges_for_class(edges, class_name, dependencies)
      end

      edges
    end

    def add_edges_for_class(edges, class_name, dependencies)
      dependencies.each do |dependency_hash|
        dependency_hash.each_key { |dependent_class| edges.add([class_name, dependent_class]) }
      end
    end
  end
end
