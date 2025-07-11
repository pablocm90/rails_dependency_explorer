# frozen_string_literal: true

require "set"

module RailsDependencyExplorer
  module Analysis
    # Encapsulates state for dependency depth calculation with memoization.
    # Manages reverse dependency graph and cached depth calculations to efficiently
    # compute how deeply nested each class is in the dependency hierarchy.
    # Handles circular dependencies by detecting cycles during calculation.
    class DepthCalculationState
      attr_reader :reverse_graph, :memo

      def initialize(reverse_graph)
        @reverse_graph = reverse_graph
        @memo = {}
        @calculating = Set.new  # Track nodes currently being calculated
      end

      def calculate_node_depth(node)
        return @memo[node] if @memo.key?(node)

        # Detect circular dependency - if we're already calculating this node,
        # it means we've found a cycle. Return 0 to break the recursion.
        return 0 if @calculating.include?(node)

        # Mark this node as being calculated
        @calculating.add(node)

        begin
          dependents = @reverse_graph[node] || []
          depth = calculate_depth_from_dependents(dependents)
          @memo[node] = depth
          depth
        ensure
          # Always remove from calculating set, even if an exception occurs
          @calculating.delete(node)
        end
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
