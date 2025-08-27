# frozen_string_literal: true

require_relative "../../output/dependency_visualizer"

module RailsDependencyExplorer
  module Analysis
    module Pipeline
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
        architectural_analysis = extract_architectural_analysis

        if architectural_analysis.any?
          visualizer.to_dot_with_architectural_analysis(@dependency_data, architectural_analysis)
        else
          visualizer.to_dot(@dependency_data)
        end
      end

      def to_json
        statistics = @statistics_provider&.statistics
        architectural_analysis = extract_architectural_analysis

        if architectural_analysis.any?
          visualizer.to_json_with_architectural_analysis(@dependency_data, statistics, architectural_analysis)
        else
          visualizer.to_json(@dependency_data, statistics)
        end
      end

      def to_html
        statistics = @statistics_provider&.statistics
        architectural_analysis = extract_architectural_analysis

        if architectural_analysis.any?
          visualizer.to_html_with_architectural_analysis(@dependency_data, statistics, architectural_analysis)
        else
          visualizer.to_html(@dependency_data, statistics)
        end
      end

      def to_console
        architectural_analysis = extract_architectural_analysis

        if architectural_analysis.any?
          visualizer.to_console_with_architectural_analysis(@dependency_data, architectural_analysis)
        else
          visualizer.to_console(@dependency_data)
        end
      end

      def to_csv
        statistics = @statistics_provider&.statistics
        architectural_analysis = extract_architectural_analysis

        if architectural_analysis.any?
          visualizer.to_csv_with_architectural_analysis(@dependency_data, statistics, architectural_analysis)
        else
          visualizer.to_csv(@dependency_data, statistics)
        end
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

      def extract_architectural_analysis
        architectural_analysis = {}

        if @statistics_provider&.respond_to?(:cross_namespace_cycles)
          cross_namespace_cycles = @statistics_provider.cross_namespace_cycles
          architectural_analysis[:cross_namespace_cycles] = cross_namespace_cycles if cross_namespace_cycles&.any?
        end

        architectural_analysis
      end
    end
    end
  end
end
