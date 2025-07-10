# frozen_string_literal: true

require_relative "../output/dependency_visualizer"

module RailsDependencyExplorer
  module Analysis
    # Handles output formatting for analysis results.
    # Separates output formatting concerns from analysis coordination,
    # following Single Responsibility Principle by focusing solely on
    # transforming analysis data into various output formats.
    class AnalysisResultFormatter
      def initialize(dependency_data, statistics_provider = nil)
        @dependency_data = dependency_data
        @statistics_provider = statistics_provider
      end

      def to_graph
        visualizer.to_graph(@dependency_data)
      end

      def to_dot
        visualizer.to_dot(@dependency_data)
      end

      def to_json
        statistics = @statistics_provider&.statistics
        visualizer.to_json(@dependency_data, statistics)
      end

      def to_html
        statistics = @statistics_provider&.statistics
        visualizer.to_html(@dependency_data, statistics)
      end

      def to_console
        visualizer.to_console(@dependency_data)
      end

      def to_csv
        statistics = @statistics_provider&.statistics
        visualizer.to_csv(@dependency_data, statistics)
      end

      def to_rails_graph
        visualizer.to_rails_graph(@dependency_data)
      end

      def to_rails_dot
        visualizer.to_rails_dot(@dependency_data)
      end

      private

      def visualizer
        @visualizer ||= Output::DependencyVisualizer.new
      end
    end
  end
end
