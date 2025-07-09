# frozen_string_literal: true

require "set"
require_relative "graph_builder"

module RailsDependencyExplorer
  module Analysis
    class CircularDependencyAnalyzer
      def initialize(dependency_data)
        @dependency_data = dependency_data
      end

      def find_cycles
        # Build adjacency list from dependency data
        graph = build_adjacency_list

        # Find cycles using DFS
        visited = Set.new
        rec_stack = Set.new
        cycles = []

        graph.keys.each do |node|
          next if visited.include?(node)
          find_cycles_dfs(node, graph, visited, rec_stack, [], cycles)
        end

        cycles
      end

      private

      def build_adjacency_list
        GraphBuilder.build_adjacency_list(@dependency_data)
      end

      def find_cycles_dfs(node, graph, visited, rec_stack, path, cycles)
        mark_node_as_visited(node, visited, rec_stack, path)

        graph[node].each do |neighbor|
          process_neighbor(neighbor, graph, visited, rec_stack, path, cycles)
        end

        unmark_node(node, rec_stack, path)
      end

      def mark_node_as_visited(node, visited, rec_stack, path)
        visited.add(node)
        rec_stack.add(node)
        path.push(node)
      end

      def process_neighbor(neighbor, graph, visited, rec_stack, path, cycles)
        if !visited.include?(neighbor)
          find_cycles_dfs(neighbor, graph, visited, rec_stack, path, cycles)
        elsif rec_stack.include?(neighbor)
          extract_cycle(neighbor, path, cycles)
        end
      end

      def extract_cycle(neighbor, path, cycles)
        cycle_start_index = path.index(neighbor)
        if cycle_start_index
          cycle = path[cycle_start_index..] + [neighbor]
          cycles << cycle unless cycles.include?(cycle)
        end
      end

      def unmark_node(node, rec_stack, path)
        rec_stack.delete(node)
        path.pop
      end
    end
  end
end
