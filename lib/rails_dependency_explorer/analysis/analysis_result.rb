# frozen_string_literal: true

require "set"
require "forwardable"
require_relative "../output/dependency_visualizer"
require_relative "circular_dependency_analyzer"
require_relative "dependency_depth_analyzer"
require_relative "dependency_statistics_calculator"

module RailsDependencyExplorer
  module Analysis
    # Coordinates dependency analysis results and provides access to various analysis components.
    # Acts as a facade for dependency exploration, circular dependency detection, depth analysis,
    # and statistics calculation. Delegates visualization and output formatting to specialized classes.
    class AnalysisResult
      extend Forwardable

      def_delegator :statistics_calculator, :calculate_statistics, :statistics
      def_delegator :circular_analyzer, :find_cycles, :circular_dependencies
      def_delegator :depth_analyzer, :calculate_depth, :dependency_depth

      def initialize(dependency_data)
        @dependency_data = dependency_data
      end

      def to_graph
        visualizer.to_graph(@dependency_data)
      end

      def to_dot
        visualizer.to_dot(@dependency_data)
      end

      def to_json
        visualizer.to_json(@dependency_data, statistics)
      end

      def to_html
        visualizer.to_html(@dependency_data, statistics)
      end

      def to_console
        visualizer.to_console(@dependency_data)
      end

      def to_csv
        visualizer.to_csv(@dependency_data, statistics)
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
