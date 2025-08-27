# frozen_string_literal: true

require "set"
require "forwardable"
require_relative "analysis_result_formatter"
require_relative "../analyzers/circular_dependency_analyzer"
require_relative "../analyzers/dependency_depth_analyzer"
require_relative "../analyzers/dependency_statistics_calculator"
require_relative "../analyzers/rails_component_analyzer"
require_relative "../analyzers/activerecord_relationship_analyzer"
require_relative "../../architectural_analysis/cross_namespace_cycle_analyzer"
require_relative "analysis_pipeline"
require_relative "analysis_result_builder"

module RailsDependencyExplorer
  # Analysis module provides core dependency analysis and coordination functionality.
  # Handles dependency exploration, circular dependency detection, depth analysis, statistics calculation,
  # Rails component categorization, and analysis result coordination. Separates analysis concerns
  # from parsing and output formatting following separation of concerns principle.
  module Analysis
    module Pipeline
      # Coordinates dependency analysis results and provides access to various analysis components.
    # Acts as a facade for dependency exploration, circular dependency detection, depth analysis,
    # and statistics calculation. Focuses solely on analysis coordination following SRP.
    class AnalysisResult
      extend Forwardable

      # Supported analyzer types for dependency injection
      ANALYZER_KEYS = [
        :circular_analyzer,
        :depth_analyzer,
        :statistics_calculator,
        :rails_component_analyzer,
        :activerecord_relationship_analyzer,
        :cross_namespace_cycle_analyzer
      ].freeze

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

      def initialize(dependency_data, analyzers: nil, use_pipeline: false)
        @dependency_data = dependency_data
        @injected_analyzers = validate_analyzers(analyzers || {})
        @use_pipeline = use_pipeline
        @pipeline_results = nil
      end

      # Factory method for creating AnalysisResult with default analyzers
      # @param dependency_data [Hash] The dependency data to analyze
      # @param container [DependencyContainer] Optional DI container for custom analyzers
      # @param use_pipeline [Boolean] Whether to use pipeline architecture (default: false for backward compatibility)
      # @return [AnalysisResult] New instance with appropriate analyzers
      def self.create(dependency_data, container: nil, use_pipeline: false)
        if use_pipeline
          create_with_pipeline(dependency_data, container: container)
        elsif container
          analyzers = build_analyzers_from_container(dependency_data, container)
          new(dependency_data, analyzers: analyzers)
        else
          new(dependency_data)
        end
      end

      # Factory method for creating AnalysisResult using pipeline architecture
      # @param dependency_data [Hash] The dependency data to analyze
      # @param container [DependencyContainer] Optional DI container for custom analyzers
      # @return [AnalysisResult] New instance using pipeline internally
      def self.create_with_pipeline(dependency_data, container: nil)
        # Create pipeline with default analyzers
        analyzers = build_pipeline_analyzers(dependency_data, container)
        pipeline = AnalysisPipeline.new(analyzers, container: container)

        # Execute pipeline
        pipeline_results = pipeline.analyze(dependency_data)

        # Build result using pipeline results
        builder = AnalysisResultBuilder.new(dependency_data)
        builder.build_from_pipeline_results(pipeline_results)
      end

      def rails_configuration_dependencies
        rails_config_analyzer.analyze_configuration_dependencies
      end

      private

      def formatter
        @formatter ||= AnalysisResultFormatter.new(@dependency_data, self)
      end

      def rails_config_analyzer
        @rails_config_analyzer ||= Analyzers::RailsConfigurationAnalyzer.new(@dependency_data)
      end

      def circular_analyzer
        @circular_analyzer ||= @injected_analyzers[:circular_analyzer] || Analyzers::CircularDependencyAnalyzer.new(@dependency_data)
      end

      def depth_analyzer
        @depth_analyzer ||= @injected_analyzers[:depth_analyzer] || Analyzers::DependencyDepthAnalyzer.new(@dependency_data)
      end

      def statistics_calculator
        @statistics_calculator ||= @injected_analyzers[:statistics_calculator] || Analyzers::DependencyStatisticsCalculator.new(@dependency_data)
      end

      def rails_component_analyzer
        @rails_component_analyzer ||= @injected_analyzers[:rails_component_analyzer] || Analyzers::RailsComponentAnalyzer.new(@dependency_data)
      end

      def activerecord_relationship_analyzer
        @activerecord_relationship_analyzer ||= @injected_analyzers[:activerecord_relationship_analyzer] || Analyzers::ActiveRecordRelationshipAnalyzer.new(@dependency_data)
      end

      def cross_namespace_cycle_analyzer
        @cross_namespace_cycle_analyzer ||= @injected_analyzers[:cross_namespace_cycle_analyzer] || ArchitecturalAnalysis::CrossNamespaceCycleAnalyzer.new(@dependency_data)
      end

      # Validate injected analyzers
      def validate_analyzers(analyzers)
        return {} unless analyzers.is_a?(Hash)

        analyzers.each do |key, analyzer|
          unless analyzer.respond_to?(:call) || analyzer.respond_to?(expected_method_for_analyzer(key))
            raise ArgumentError, "Invalid analyzer for #{key}: must respond to expected methods"
          end
        end

        analyzers
      end

      # Get expected method name for analyzer type
      def expected_method_for_analyzer(analyzer_key)
        case analyzer_key
        when :circular_analyzer then :find_cycles
        when :depth_analyzer then :calculate_depth
        when :statistics_calculator then :calculate_statistics
        when :rails_component_analyzer then :categorize_components
        when :activerecord_relationship_analyzer then :analyze_relationships
        when :cross_namespace_cycle_analyzer then :find_cross_namespace_cycles
        else :call
        end
      end

      # Build analyzers from dependency container
      def self.build_analyzers_from_container(dependency_data, container)
        analyzers = {}

        ANALYZER_KEYS.each do |key|
          if container.registered?(key)
            analyzers[key] = container.resolve(key, dependency_data)
          end
        end

        analyzers
      end

      # Build analyzers for pipeline execution
      def self.build_pipeline_analyzers(dependency_data, container)
        analyzers = []

        # Add default analyzers directly (no adapter needed)
        # Configure analyzers to return raw results (not metadata-wrapped) for pipeline use

        # BaseAnalyzer-based analyzers support include_metadata option
        analyzers << Analyzers::DependencyStatisticsCalculator.new(dependency_data, include_metadata: false)
        analyzers << Analyzers::CircularDependencyAnalyzer.new(dependency_data, include_metadata: false)
        analyzers << Analyzers::DependencyDepthAnalyzer.new(dependency_data, include_metadata: false)
        analyzers << Analyzers::RailsComponentAnalyzer.new(dependency_data, include_metadata: false)
        analyzers << Analyzers::ActiveRecordRelationshipAnalyzer.new(dependency_data, include_metadata: false)

        # CrossNamespaceCycleAnalyzer has different constructor signature (doesn't inherit from BaseAnalyzer)
        # It returns raw results by default, so no configuration needed
        analyzers << ArchitecturalAnalysis::CrossNamespaceCycleAnalyzer.new(dependency_data)

        # Add container-based analyzers if available
        if container
          ANALYZER_KEYS.each do |key|
            if container.registered?(key)
              custom_analyzer = container.resolve(key, dependency_data)
              analyzers << custom_analyzer
            end
          end
        end

        analyzers
      end
    end


    end
  end
end
