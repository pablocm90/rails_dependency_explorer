# frozen_string_literal: true

require "set"
require_relative "base_analyzer"
require_relative "depth_calculation_state"

module RailsDependencyExplorer
  module Analysis
    # Calculates the dependency depth for each class in a Rails application.
    # Depth represents how many layers of dependencies a class has, helping identify
    # classes that are deeply nested in the dependency hierarchy.
    class DependencyDepthAnalyzer < BaseAnalyzer

      # Implementation of BaseAnalyzer template method
      def perform_analysis
        calculate_depth
      end

      def calculate_depth
        graph = build_adjacency_list
        reverse_graph = build_reverse_adjacency_list(graph)
        all_nodes = extract_all_nodes(graph)
        self.class.calculate_depths_for_nodes(reverse_graph, all_nodes)
      end

      def self.calculate_depths_for_nodes(reverse_graph, all_nodes)
        state = DepthCalculationState.new(reverse_graph)
        all_nodes.each_with_object({}) do |node, depths|
          depths[node] = state.calculate_node_depth(node)
        end
      end

      def extract_all_nodes(graph)
        all_nodes = Set.new(@dependency_data.keys)
        add_graph_nodes_to_set(graph, all_nodes)
        all_nodes
      end

      def add_graph_nodes_to_set(graph, all_nodes)
        graph.each do |node, neighbors|
          all_nodes.add(node)
          self.class.add_neighbors_to_set(neighbors, all_nodes)
        end
      end

      def self.add_neighbors_to_set(neighbors, all_nodes)
        neighbors.each { |neighbor| all_nodes.add(neighbor) }
      end

      def build_reverse_adjacency_list(graph)
        reverse_graph = Hash.new { |h, k| h[k] = [] }
        populate_reverse_graph(graph, reverse_graph)
        reverse_graph
      end

      def populate_reverse_graph(graph, reverse_graph)
        graph.each do |node, neighbors|
          add_reverse_dependencies(node, neighbors, reverse_graph)
        end
      end

      def add_reverse_dependencies(node, neighbors, reverse_graph)
        neighbors.each do |neighbor|
          self.class.add_unique_dependency(reverse_graph, neighbor, node)
        end
      end

      def self.add_unique_dependency(reverse_graph, neighbor, node)
        neighbor_dependencies = reverse_graph[neighbor]
        neighbor_dependencies << node unless neighbor_dependencies.include?(node)
      end
    end
  end
end
