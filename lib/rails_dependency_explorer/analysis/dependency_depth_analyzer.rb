# frozen_string_literal: true

require "set"
require_relative "graph_builder"

module RailsDependencyExplorer
  module Analysis
    class DependencyDepthAnalyzer
      def initialize(dependency_data)
        @dependency_data = dependency_data
      end

      def calculate_depth
        graph = build_adjacency_list
        reverse_graph = build_reverse_adjacency_list(graph)
        all_nodes = extract_all_nodes(graph)

        # Calculate depth for each node from reverse perspective
        memo = {}
        all_nodes.each_with_object({}) do |node, depths|
          depths[node] = calculate_node_depth(node, reverse_graph, memo)
        end
      end

      private

      def build_adjacency_list
        GraphBuilder.build_adjacency_list(@dependency_data)
      end

      def extract_all_nodes(graph)
        all_nodes = Set.new(@dependency_data.keys)
        add_graph_nodes_to_set(graph, all_nodes)
        all_nodes
      end

      def add_graph_nodes_to_set(graph, all_nodes)
        graph.each do |node, neighbors|
          all_nodes.add(node)
          add_neighbors_to_set(neighbors, all_nodes)
        end
      end

      def add_neighbors_to_set(neighbors, all_nodes)
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
          add_unique_dependency(reverse_graph, neighbor, node)
        end
      end

      def add_unique_dependency(reverse_graph, neighbor, node)
        reverse_graph[neighbor] << node unless reverse_graph[neighbor].include?(node)
      end

      def calculate_node_depth(node, reverse_graph, memo)
        return memo[node] if memo.key?(node)

        dependents = reverse_graph[node] || []
        depth = calculate_depth_from_dependents(dependents, reverse_graph, memo)
        memo[node] = depth
        depth
      end

      def calculate_depth_from_dependents(dependents, reverse_graph, memo)
        return 0 if dependents.empty?

        max_dependent_depth = find_max_dependent_depth(dependents, reverse_graph, memo)
        max_dependent_depth + 1
      end

      def find_max_dependent_depth(dependents, reverse_graph, memo)
        dependents.map { |dep| calculate_node_depth(dep, reverse_graph, memo) }.max || 0
      end
    end
  end
end
