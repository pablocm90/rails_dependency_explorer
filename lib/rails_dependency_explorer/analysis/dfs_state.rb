# frozen_string_literal: true

require "set"

module RailsDependencyExplorer
  module Analysis
    # Encapsulates state for depth-first search traversal during circular dependency detection.
    # Manages visited nodes, recursion stack, current path, and detected cycles to eliminate
    # parameter passing between DFS methods and improve code organization.
    class DfsState
      attr_reader :visited, :rec_stack, :path, :cycles

      def initialize
        @visited = Set.new
        @rec_stack = Set.new
        @path = []
        @cycles = []
      end

      def mark_node_as_visited(node)
        @visited.add(node)
        @rec_stack.add(node)
        @path.push(node)
      end

      def unmark_node(node)
        @rec_stack.delete(node)
        @path.pop
      end

      def node_visited?(node)
        @visited.include?(node)
      end

      def node_in_recursion_stack?(node)
        @rec_stack.include?(node)
      end

      def extract_cycle(neighbor)
        cycle_start_index = @path.index(neighbor)
        if cycle_start_index
          cycle = @path[cycle_start_index..] + [neighbor]
          @cycles << cycle unless @cycles.include?(cycle)
        end
      end
    end
  end
end
