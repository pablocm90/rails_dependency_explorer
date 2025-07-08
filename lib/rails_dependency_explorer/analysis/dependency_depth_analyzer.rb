# frozen_string_literal: true

require "set"

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
        graph = Hash.new { |h, k| h[k] = [] }

        @dependency_data.each do |class_name, dependencies|
          dependencies.each do |dep|
            if dep.is_a?(Hash)
              dep.each do |constant, methods|
                graph[class_name] << constant unless graph[class_name].include?(constant)
              end
            end
          end
        end

        graph
      end

      def extract_all_nodes(graph)
        all_nodes = Set.new(@dependency_data.keys)
        graph.each { |node, neighbors|
          all_nodes.add(node)
          neighbors.each { |n| all_nodes.add(n) }
        }
        all_nodes
      end

      def build_reverse_adjacency_list(graph)
        reverse_graph = Hash.new { |h, k| h[k] = [] }

        graph.each do |node, neighbors|
          neighbors.each do |neighbor|
            reverse_graph[neighbor] << node unless reverse_graph[neighbor].include?(node)
          end
        end

        reverse_graph
      end

      def calculate_node_depth(node, reverse_graph, memo)
        return memo[node] if memo.key?(node)

        # If no one depends on this node, depth is 0 (root level)
        dependents = reverse_graph[node] || []
        if dependents.empty?
          memo[node] = 0
          return 0
        end

        # Depth is 1 + max depth of dependents
        max_dependent_depth = dependents.map { |dep| calculate_node_depth(dep, reverse_graph, memo) }.max || 0
        memo[node] = max_dependent_depth + 1
        memo[node]
      end
    end
  end
end
