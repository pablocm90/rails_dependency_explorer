# frozen_string_literal: true

require "set"
require_relative "../output/dependency_visualizer"

module RailsDependencyExplorer
  module Analysis
    class AnalysisResult
      def initialize(dependency_data)
        @dependency_data = dependency_data
      end

      def to_graph
        visualizer.to_graph(@dependency_data)
      end

      def to_dot
        visualizer.to_dot(@dependency_data)
      end

      def statistics
        dependency_counts = calculate_dependency_counts
        most_used = dependency_counts.max_by { |_, count| count }

        {
          total_classes: @dependency_data.keys.count,
          total_dependencies: dependency_counts.keys.count,
          most_used_dependency: most_used ? most_used[0] : nil,
          dependency_counts: dependency_counts
        }
      end

      def circular_dependencies
        find_cycles_in_dependency_graph
      end

      private

      def visualizer
        @visualizer ||= Output::DependencyVisualizer.new
      end

      def calculate_dependency_counts
        counts = Hash.new(0)

        @dependency_data.each do |class_name, dependencies|
          dependencies.each do |dep|
            if dep.is_a?(Hash)
              dep.each do |constant, methods|
                # Count each occurrence of the constant (once per dependency hash)
                counts[constant] += 1
              end
            end
          end
        end

        counts
      end

      def find_cycles_in_dependency_graph
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
              cycle = path[cycle_start_index..] + [neighbor]
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
