# frozen_string_literal: true

require "thread"
require_relative "analyzer_registry"
require_relative "analysis_result_builder"
require_relative "../../error_handler"

module RailsDependencyExplorer
  module Analysis
    module Pipeline
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
        # Check cache first if caching is enabled
        if @config[:enable_caching]
          cache_key = generate_cache_key(dependency_data)
          cached_result = get_cached_result(cache_key)
          return cached_result if cached_result
        end

        results = {}
        errors = []

        if @config[:parallel_execution] && @analyzers.size > 1
          # Execute analyzers in parallel
          execute_analyzers_in_parallel(dependency_data, results, errors)
        else
          # Execute analyzers sequentially
          execute_analyzers_sequentially(dependency_data, results, errors)
        end

        results[:errors] = errors unless errors.empty?

        # Cache results if caching is enabled
        if @config[:enable_caching]
          cache_result(cache_key, results)
        end

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
          timeout: 30,
          enable_caching: false,
          memory_optimization: false
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
        return unless analyzer_result

        if analyzer.respond_to?(:analyzer_key)
          # Use analyzer's preferred key and store the raw result
          key = analyzer.analyzer_key
          results[key] = analyzer_result
        elsif analyzer_result.is_a?(Hash)
          # Merge all keys from analyzer result
          results.merge!(analyzer_result)
        end
      end

      def handle_analyzer_error(errors, analyzer, error)
        case @config[:error_handling]
        when :continue
          error_result = create_standardized_error_result(analyzer, error)
          errors << error_result
        when :stop
          raise error
        else
          # Default to continue
          error_result = create_standardized_error_result(analyzer, error)
          errors << error_result
        end
      end

      def create_standardized_error_result(analyzer, error)
        # Handle anonymous classes safely
        analyzer_name = if analyzer.class.name
                         analyzer.class.name.split("::").last
                       else
                         "AnonymousAnalyzer"
                       end

        RailsDependencyExplorer::ErrorHandler.create_error_result(
          error,
          context: "AnalysisPipeline",
          operation: "execute_analyzer(#{analyzer_name})"
        )
      end

      # Execute analyzers sequentially (original behavior)
      def execute_analyzers_sequentially(dependency_data, results, errors)
        @analyzers.each do |analyzer|
          begin
            analyzer_result = execute_analyzer(analyzer, dependency_data)
            merge_analyzer_result(results, analyzer_result, analyzer)
          rescue StandardError => e
            handle_analyzer_error(errors, analyzer, e)
          end
        end
      end

      # Execute analyzers in parallel using threads
      def execute_analyzers_in_parallel(dependency_data, results, errors)
        threads = []
        thread_results = {}
        thread_errors = []
        mutex = Mutex.new

        @analyzers.each_with_index do |analyzer, index|
          threads << Thread.new do
            begin
              analyzer_result = execute_analyzer(analyzer, dependency_data)
              mutex.synchronize do
                thread_results[index] = { analyzer: analyzer, result: analyzer_result }
              end
            rescue StandardError => e
              mutex.synchronize do
                thread_errors << { analyzer: analyzer, error: e }
              end
            end
          end
        end

        # Wait for all threads to complete
        threads.each(&:join)

        # Merge results in original order to maintain consistency
        thread_results.keys.sort.each do |index|
          data = thread_results[index]
          merge_analyzer_result(results, data[:result], data[:analyzer])
        end

        # Handle errors
        thread_errors.each do |error_data|
          handle_analyzer_error(errors, error_data[:analyzer], error_data[:error])
        end
      end

      # Simple caching implementation
      def initialize_cache
        @cache ||= {}
      end

      def generate_cache_key(dependency_data)
        # Simple cache key based on data hash
        dependency_data.hash.to_s
      end

      def get_cached_result(cache_key)
        initialize_cache
        @cache[cache_key]
      end

      def cache_result(cache_key, results)
        initialize_cache
        @cache[cache_key] = results.dup
      end
    end
    end
  end
end
