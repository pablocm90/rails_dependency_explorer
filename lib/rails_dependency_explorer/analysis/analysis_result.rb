# frozen_string_literal: true

require "set"
require_relative "../output/dependency_visualizer"
require_relative "circular_dependency_analyzer"

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
        circular_analyzer.find_cycles
      end

      def dependency_depth
        calculate_dependency_depth
      end

      private

      def visualizer
        @visualizer ||= Output::DependencyVisualizer.new
      end

      def circular_analyzer
        @circular_analyzer ||= CircularDependencyAnalyzer.new(@dependency_data)
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



      def calculate_dependency_depth
        graph = build_adjacency_list
        reverse_graph = build_reverse_adjacency_list(graph)
        all_nodes = extract_all_nodes(graph)

        # Calculate depth for each node from reverse perspective
        memo = {}
        all_nodes.each_with_object({}) do |node, depths|
          depths[node] = calculate_node_depth(node, reverse_graph, memo)
        end
      end

      def extract_all_nodes(graph)
        all_nodes = Set.new(@dependency_data.keys)
        graph.each { |node, neighbors| all_nodes.add(node); neighbors.each { |n| all_nodes.add(n) } }
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
