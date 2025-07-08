# frozen_string_literal: true

require "set"
require_relative "../output/dependency_visualizer"
require_relative "circular_dependency_analyzer"
require_relative "dependency_depth_analyzer"
require_relative "dependency_statistics_calculator"

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
        statistics_calculator.calculate_statistics
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

      def statistics_calculator
        @statistics_calculator ||= DependencyStatisticsCalculator.new(@dependency_data)
      end






    end
  end
end
