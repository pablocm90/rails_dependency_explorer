# frozen_string_literal: true

require "set"
require "forwardable"
require_relative "analysis_result_formatter"
require_relative "circular_dependency_analyzer"
require_relative "dependency_depth_analyzer"
require_relative "dependency_statistics_calculator"
require_relative "rails_component_analyzer"
require_relative "activerecord_relationship_analyzer"
require_relative "../architectural_analysis/cross_namespace_cycle_analyzer"

module RailsDependencyExplorer
  module Analysis
    # Coordinates dependency analysis results and provides access to various analysis components.
    # Acts as a facade for dependency exploration, circular dependency detection, depth analysis,
    # and statistics calculation. Focuses solely on analysis coordination following SRP.
    class AnalysisResult
      extend Forwardable

      # Analysis coordination delegations
      def_delegator :statistics_calculator, :calculate_statistics, :statistics
      def_delegator :circular_analyzer, :find_cycles, :circular_dependencies
      def_delegator :depth_analyzer, :calculate_depth, :dependency_depth
      def_delegator :rails_component_analyzer, :categorize_components, :rails_components
      def_delegator :activerecord_relationship_analyzer, :analyze_relationships, :activerecord_relationships
      def_delegator :cross_namespace_cycle_analyzer, :find_cross_namespace_cycles, :cross_namespace_cycles

      # Output formatting delegations
      def_delegator :formatter, :to_graph
      def_delegator :formatter, :to_dot
      def_delegator :formatter, :to_json
      def_delegator :formatter, :to_html
      def_delegator :formatter, :to_console
      def_delegator :formatter, :to_csv
      def_delegator :formatter, :to_rails_graph
      def_delegator :formatter, :to_rails_dot

      def initialize(dependency_data)
        @dependency_data = dependency_data
      end

      def rails_configuration_dependencies
        rails_config_analyzer.analyze_configuration_dependencies
      end

      private

      def formatter
        @formatter ||= AnalysisResultFormatter.new(@dependency_data, self)
      end

      def rails_config_analyzer
        @rails_config_analyzer ||= RailsConfigurationAnalyzer.new(@dependency_data)
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

      def rails_component_analyzer
        @rails_component_analyzer ||= RailsComponentAnalyzer.new(@dependency_data)
      end

      def activerecord_relationship_analyzer
        @activerecord_relationship_analyzer ||= ActiveRecordRelationshipAnalyzer.new(@dependency_data)
      end

      def cross_namespace_cycle_analyzer
        @cross_namespace_cycle_analyzer ||= ArchitecturalAnalysis::CrossNamespaceCycleAnalyzer.new(@dependency_data)
      end
    end
  end
end
