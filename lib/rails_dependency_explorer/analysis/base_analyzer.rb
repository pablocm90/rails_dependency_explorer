# frozen_string_literal: true

require_relative "analyzer_interface"
require_relative "graph_builder"

module RailsDependencyExplorer
  module Analysis
    # Base class for all dependency analyzers providing common functionality.
    # Implements the Template Method pattern where subclasses override perform_analysis
    # while the base class handles common concerns like error handling, validation,
    # and result formatting.
    class BaseAnalyzer
      include AnalyzerInterface

      attr_reader :dependency_data, :options

      # Initialize analyzer with dependency data and optional configuration
      # @param dependency_data [Hash] The dependency data to analyze
      # @param options [Hash] Configuration options for the analyzer
      def initialize(dependency_data, **options)
        @dependency_data = dependency_data
        @options = default_options.merge(options)
        validate_dependency_data if @options[:validate_on_init]
      end

      # Implementation of AnalyzerInterface - Template Method pattern
      # Handles error handling and result formatting, delegates actual analysis to perform_analysis
      def analyze
        return handle_analysis_error if @options[:error_handling] == :graceful && !validate_dependency_data

        begin
          raw_result = perform_analysis
          @options[:include_metadata] ? format_result(raw_result) : raw_result
        rescue StandardError => e
          handle_analysis_exception(e)
        end
      end

      # Template method for subclasses to implement their specific analysis logic
      # @return [Object] Analysis results specific to the analyzer type
      def perform_analysis
        raise NotImplementedError, "#{self.class} must implement #perform_analysis"
      end

      # Build adjacency list representation of dependency graph
      # @return [Hash] Adjacency list where keys are classes and values are arrays of dependencies
      def build_adjacency_list
        GraphBuilder.build_adjacency_list(@dependency_data)
      end

      # Validate that dependency data is in expected format
      # @return [Boolean] true if data is valid, false otherwise
      def validate_dependency_data
        return false unless valid_dependency_data_structure?

        @dependency_data.all? { |class_name, dependencies| valid_dependency_entry?(class_name, dependencies) }
      end

      # Get metadata about this analyzer and the analysis context
      # @return [Hash] Metadata including analyzer class, dependency count, and timestamp
      def metadata
        {
          analyzer_class: self.class.name,
          dependency_count: @dependency_data&.keys&.count || 0,
          analysis_timestamp: Time.now,
          options: @options
        }
      end

      # Format analysis result with metadata if requested
      # @param raw_result [Object] The raw analysis result
      # @return [Hash] Formatted result with metadata
      def format_result(raw_result)
        {
          result: raw_result,
          metadata: metadata
        }
      end

      private

      # Default configuration options for analyzers
      def default_options
        {
          include_metadata: true,
          error_handling: :graceful,
          validate_on_init: true
        }
      end

      # Check if dependency data has valid top-level structure
      def valid_dependency_data_structure?
        !@dependency_data.nil? && @dependency_data.is_a?(Hash)
      end

      # Check if individual dependency entry is valid
      def valid_dependency_entry?(class_name, dependencies)
        class_name.is_a?(String) && dependencies.is_a?(Array)
      end

      # Handle analysis exceptions based on error handling mode
      def handle_analysis_exception(exception)
        return raise exception if strict_error_handling?

        create_error_result(exception.message, exception.class.name, exception.backtrace&.first(5))
      end

      # Handle case where dependency data validation fails
      def handle_analysis_error
        create_error_result("Invalid dependency data provided to analyzer", "ValidationError")
      end

      # Check if strict error handling is enabled
      def strict_error_handling?
        @options[:error_handling] == :strict
      end

      # Create standardized error result structure
      def create_error_result(message, type, backtrace = nil)
        error_data = { message: message, type: type }
        error_data[:backtrace] = backtrace if backtrace
        { error: error_data }
      end
    end
  end
end
