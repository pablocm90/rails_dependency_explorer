# frozen_string_literal: true

require_relative "analyzer_registry"
require_relative "analysis_result_builder"

module RailsDependencyExplorer
  module Analysis
    # Pipeline for executing multiple analyzers in sequence.
    # Replaces AnalysisResult coordination with composable analyzer architecture.
    # Part of Phase 3.1 pipeline architecture implementation.
    class AnalysisPipeline
      attr_reader :config

      def initialize(analyzers = [], container: nil, config: {})
        @analyzers = analyzers
        @container = container
        @config = default_config.merge(config)
      end

      # Create pipeline from analyzer registry
      def self.from_registry(registry)
        analyzers = registry.list_registered.map do |key|
          registry.create_analyzer(key)
        end
        
        new(analyzers)
      end

      # Execute pipeline analysis
      def analyze(dependency_data)
        results = {}
        errors = []
        
        @analyzers.each do |analyzer|
          begin
            analyzer_result = execute_analyzer(analyzer, dependency_data)
            merge_analyzer_result(results, analyzer_result, analyzer)
          rescue StandardError => e
            handle_analyzer_error(errors, analyzer, e)
          end
        end
        
        results[:errors] = errors unless errors.empty?
        results
      end

      # Add analyzer from container
      def add_analyzer_from_container(key)
        return unless @container&.registered?(key)
        
        analyzer = @container.resolve(key)
        @analyzers << analyzer
      end

      private

      def default_config
        {
          parallel_execution: false,
          error_handling: :continue,
          timeout: 30
        }
      end

      def execute_analyzer(analyzer, dependency_data)
        if analyzer.respond_to?(:analyze)
          analyzer.analyze(dependency_data)
        else
          raise StandardError, "Analyzer does not respond to #analyze method"
        end
      end

      def merge_analyzer_result(results, analyzer_result, analyzer)
        return unless analyzer_result.is_a?(Hash)
        
        if analyzer.respond_to?(:analyzer_key)
          # Use analyzer's preferred key
          key = analyzer.analyzer_key
          results[key] = analyzer_result[key] if analyzer_result.key?(key)
        else
          # Merge all keys from analyzer result
          results.merge!(analyzer_result)
        end
      end

      def handle_analyzer_error(errors, analyzer, error)
        case @config[:error_handling]
        when :continue
          error_message = build_error_message(analyzer, error)
          errors << error_message
        when :stop
          raise error
        else
          # Default to continue
          error_message = build_error_message(analyzer, error)
          errors << error_message
        end
      end

      def build_error_message(analyzer, error)
        analyzer_name = analyzer.class.name.split("::").last
        "#{analyzer_name} execution failed"
      end
    end
  end
end
