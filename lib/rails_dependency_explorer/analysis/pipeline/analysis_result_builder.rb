# frozen_string_literal: true

# Note: AnalysisResult is required dynamically to avoid circular dependency

module RailsDependencyExplorer
  module Analysis
    module Pipeline
      # Builder for composing analysis results from pipeline execution.
    # Handles result aggregation, error collection, and AnalysisResult facade creation.
    # Part of Phase 3.1 pipeline architecture implementation.
    class AnalysisResultBuilder
      def initialize(dependency_data)
        @dependency_data = dependency_data
        @result_processors = {}
      end

      # Build AnalysisResult from pipeline results
      def build_from_pipeline_results(pipeline_results)
        raise ArgumentError, "Pipeline results must be a Hash" unless pipeline_results.is_a?(Hash)
        
        processed_results = apply_result_processors(pipeline_results)
        create_analysis_result(processed_results)
      end

      # Merge multiple result sets
      def merge_results(result_sets)
        merged = {}
        errors = []
        
        result_sets.each do |results|
          next unless results.is_a?(Hash)
          
          results.each do |key, value|
            if key == :errors
              errors.concat(Array(value))
            else
              merged[key] = value
            end
          end
        end
        
        merged[:errors] = errors unless errors.empty?
        merged
      end

      # Add custom result processor
      def add_result_processor(key, &block)
        @result_processors[key] = block
      end

      private

      def apply_result_processors(results)
        processed = results.dup
        
        @result_processors.each do |key, processor|
          if processed.key?(key)
            processed[key] = processor.call(processed[key])
          end
        end
        
        processed
      end

      def create_analysis_result(processed_results)
        # Require AnalysisResult dynamically to avoid circular dependency
        require_relative "analysis_result" unless defined?(AnalysisResult)

        # Create AnalysisResult with pipeline data
        result = AnalysisResult.new(@dependency_data)
        
        # Override internal data with pipeline results
        result.instance_variable_set(:@pipeline_results, processed_results)
        
        # Extend result with pipeline-specific methods
        extend_with_pipeline_methods(result, processed_results)
        
        result
      end

      def extend_with_pipeline_methods(result, pipeline_results)
        # Add errors method if errors exist
        if pipeline_results.key?(:errors)
          result.define_singleton_method(:errors) do
            pipeline_results[:errors]
          end
        else
          result.define_singleton_method(:errors) do
            []
          end
        end
        
        # Add metadata method if metadata exists
        if pipeline_results.key?(:metadata)
          result.define_singleton_method(:metadata) do
            pipeline_results[:metadata]
          end
        else
          result.define_singleton_method(:metadata) do
            {}
          end
        end
        
        # Override existing methods with pipeline results
        override_analysis_methods(result, pipeline_results)
      end

      def override_analysis_methods(result, pipeline_results)
        # Override statistics
        if pipeline_results.key?(:statistics)
          result.define_singleton_method(:statistics) do
            pipeline_results[:statistics]
          end
        else
          result.define_singleton_method(:statistics) do
            {}
          end
        end
        
        # Override circular_dependencies
        if pipeline_results.key?(:circular_dependencies)
          result.define_singleton_method(:circular_dependencies) do
            pipeline_results[:circular_dependencies]
          end
        else
          result.define_singleton_method(:circular_dependencies) do
            []
          end
        end
        
        # Override dependency_depth
        if pipeline_results.key?(:dependency_depth)
          result.define_singleton_method(:dependency_depth) do
            pipeline_results[:dependency_depth]
          end
        else
          result.define_singleton_method(:dependency_depth) do
            {}
          end
        end
        
        # Override rails_components
        if pipeline_results.key?(:rails_components)
          result.define_singleton_method(:rails_components) do
            pipeline_results[:rails_components]
          end
        else
          result.define_singleton_method(:rails_components) do
            { models: [], controllers: [], services: [], other: [] }
          end
        end
      end
    end
    end
  end
end
