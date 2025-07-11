# frozen_string_literal: true

require "set"
require_relative "analyzer_interface"
require_relative "cycle_detection_interface"
require_relative "graph_builder"
require_relative "dfs_state"

module RailsDependencyExplorer
  module Analysis
    # Detects circular dependencies in Rails applications using depth-first search algorithm.
    # Analyzes dependency graphs to identify cycles where classes depend on each other directly
    # or indirectly, which can indicate architectural problems or potential runtime issues.
    class CircularDependencyAnalyzer
      include AnalyzerInterface
      include CycleDetectionInterface
      def initialize(dependency_data)
        @dependency_data = dependency_data
      end

      # Implementation of AnalyzerInterface
      def analyze
        find_cycles
      end

      def find_cycles
        graph = build_adjacency_list
        state = DfsState.new
        traverse_graph_for_cycles(graph, state)
        state.cycles
      end

      private

      def traverse_graph_for_cycles(graph, state)
        graph.keys.each do |node|
          next if state.node_visited?(node)
          find_cycles_dfs(node, graph, state)
        end
      end

      def build_adjacency_list
        GraphBuilder.build_adjacency_list(@dependency_data)
      end

      def find_cycles_dfs(node, graph, state)
        state.mark_node_as_visited(node)

        graph[node].each do |neighbor|
          process_neighbor(neighbor, graph, state)
        end

        state.unmark_node(node)
      end

      def process_neighbor(neighbor, graph, state)
        if !state.node_visited?(neighbor)
          find_cycles_dfs(neighbor, graph, state)
        elsif state.node_in_recursion_stack?(neighbor)
          state.extract_cycle(neighbor)
        end
      end
    end
  end
end
