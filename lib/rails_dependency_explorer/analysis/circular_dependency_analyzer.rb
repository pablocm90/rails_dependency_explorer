# frozen_string_literal: true

require "set"
require_relative "graph_builder"
require_relative "dfs_state"

module RailsDependencyExplorer
  module Analysis
    class CircularDependencyAnalyzer
      def initialize(dependency_data)
        @dependency_data = dependency_data
      end

      def find_cycles
        # Build adjacency list from dependency data
        graph = build_adjacency_list

        # Find cycles using DFS with state object
        state = DfsState.new

        graph.keys.each do |node|
          next if state.node_visited?(node)
          find_cycles_dfs(node, graph, state)
        end

        state.cycles
      end

      private

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
