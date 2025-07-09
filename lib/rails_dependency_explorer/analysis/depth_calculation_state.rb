# frozen_string_literal: true

module RailsDependencyExplorer
  module Analysis
    # Encapsulates state for dependency depth calculation with memoization.
    # Manages reverse dependency graph and cached depth calculations to efficiently
    # compute how deeply nested each class is in the dependency hierarchy.
    class DepthCalculationState
      attr_reader :reverse_graph, :memo

      def initialize(reverse_graph)
        @reverse_graph = reverse_graph
        @memo = {}
      end

      def calculate_node_depth(node)
        return @memo[node] if @memo.key?(node)

        dependents = @reverse_graph[node] || []
        depth = calculate_depth_from_dependents(dependents)
        @memo[node] = depth
        depth
      end

      private

      def calculate_depth_from_dependents(dependents)
        return 0 if dependents.empty?

        max_dependent_depth = find_max_dependent_depth(dependents)
        max_dependent_depth + 1
      end

      def find_max_dependent_depth(dependents)
        dependents.map { |dep| calculate_node_depth(dep) }.max || 0
      end
    end
  end
end
