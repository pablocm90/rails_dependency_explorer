# frozen_string_literal: true

require "set"

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

      def find_cycles_dfs(node, graph, visited, rec_stack, path, cycles)
        visited.add(node)
        rec_stack.add(node)
        path.push(node)

        graph[node].each do |neighbor|
          if !visited.include?(neighbor)
            find_cycles_dfs(neighbor, graph, visited, rec_stack, path, cycles)
          elsif rec_stack.include?(neighbor)
            # Found a cycle
            cycle_start_index = path.index(neighbor)
            if cycle_start_index
              cycle = path[cycle_start_index..-1] + [neighbor]
              cycles << cycle unless cycles.include?(cycle)
            end
          end
        end

        rec_stack.delete(node)
        path.pop
      end
    end
  end
end
