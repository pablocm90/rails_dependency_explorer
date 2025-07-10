# frozen_string_literal: true

require_relative "path_validator"
require_relative "analysis_executor"

module RailsDependencyExplorer
  module CLI
    # Coordinates analysis operations by orchestrating path validation,
    # option parsing, and analysis execution. Separates high-level coordination
    # from specific operational concerns, following SRP.
    # Extracted from AnalyzeCommand as part of H3 refactoring.
    class AnalysisCoordinator
      attr_reader :analysis_executor

      def initialize(parser, output_writer)
        @parser = parser
        @path_validator = PathValidator.new
        @analysis_executor = AnalysisExecutor.new(output_writer)
      end

      # Main coordination method that orchestrates the analysis workflow:
      # 1. Get and validate the path for the analysis type
      # 2. Parse command-line options (format, output file, etc.)
      # 3. Build output options from parsed flags
      # 4. Execute the appropriate analysis type
      def coordinate_analysis(analysis_type)
        path = get_path_for_analysis_type(analysis_type)
        return 1 unless validate_path_for_analysis_type(analysis_type, path)

        parse_result = parse_directory_options
        exit_code = parse_result[:exit_code]
        return exit_code if exit_code

        output_options = build_output_options

        case analysis_type
        when :file
          @analysis_executor.perform_file_analysis(path, parse_result[:format], parse_result[:output_file], output_options)
        when :directory
          @analysis_executor.perform_directory_analysis(path, parse_result[:format], parse_result[:output_file], output_options)
        end
      end

      private

      def get_path_for_analysis_type(analysis_type)
        case analysis_type
        when :file
          @parser.get_file_path
        when :directory
          @parser.get_directory_path
        end
      end

      def validate_path_for_analysis_type(analysis_type, path)
        case analysis_type
        when :file
          @path_validator.validate_file_path(path)
        when :directory
          validation_result = @path_validator.validate_directory_path(path)
          validation_result != 1
        end
      end

      def parse_directory_options
        format = @parser.parse_format_option
        return {exit_code: 1} if format.nil?

        output_file = @parser.parse_output_option
        return {exit_code: 1} if output_file == :error

        {format: format, output_file: output_file, exit_code: nil}
      end

      def build_output_options
        {
          include_stats: @parser.has_stats_option?,
          include_circular: @parser.has_circular_option?,
          include_depth: @parser.has_depth_option?
        }
      end
    end
  end
end
