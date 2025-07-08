# frozen_string_literal: true

require "set"
require_relative "../output/dependency_visualizer"
require_relative "circular_dependency_analyzer"
require_relative "dependency_depth_analyzer"

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
        depth_analyzer.calculate_depth
      end

      private

      def visualizer
        @visualizer ||= Output::DependencyVisualizer.new
      end

      def circular_analyzer
        @circular_analyzer ||= CircularDependencyAnalyzer.new(@dependency_data)
      end

      def depth_analyzer
        @depth_analyzer ||= DependencyDepthAnalyzer.new(@dependency_data)
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




    end
  end
end
