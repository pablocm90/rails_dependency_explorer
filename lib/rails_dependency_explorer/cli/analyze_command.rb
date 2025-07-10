# frozen_string_literal: true

require_relative "../analysis/dependency_explorer"
require_relative "error_handler"

module RailsDependencyExplorer
  module CLI
    # Handles the 'analyze' command for the Rails dependency explorer CLI.
    # Processes command-line arguments, performs dependency analysis on files or directories,
    # and coordinates output formatting and writing through the OutputWriter.
    class AnalyzeCommand
      def initialize(parser, output_writer)
        @parser = parser
        @output_writer = output_writer
      end

      def execute
        # Check for directory analysis option
        if @parser.has_directory_option?
          return analyze_directory
        end

        analyze_file
      end

      def self.analyze_single_file(file_path)
        ruby_code = File.read(file_path)
        explorer = Analysis::DependencyExplorer.new
        explorer.analyze_code(ruby_code)
      end

      def self.analyze_directory_files(directory_path)
        explorer = Analysis::DependencyExplorer.new
        explorer.analyze_directory(directory_path)
      end

      private

      def analyze_file
        coordinate_analysis(:file) do |path, format, output_file|
          perform_file_analysis(path, format, output_file)
        end
      end

      def validate_file_path(file_path)
        return false unless check_file_path_provided(file_path)
        return false unless check_file_exists(file_path)
        true
      end

      def check_file_path_provided(file_path)
        return true unless file_path.nil?
        ErrorHandler.handle_missing_path_error(:file)
      end

      def check_file_exists(file_path)
        return true if File.exist?(file_path)
        ErrorHandler.handle_not_found_error(:file, file_path)
      end

      def perform_file_analysis(file_path, format, output_file)
        result = analyze_single_file(file_path)
        write_analysis_output(result, format, output_file)
        0
      rescue => e
        ErrorHandler.handle_analysis_error("file", e)
      end

      def analyze_single_file(file_path)
        self.class.analyze_single_file(file_path)
      end

      def write_analysis_output(result, format, output_file)
        output_content = @output_writer.format_output(result, format, build_output_options)
        @output_writer.write_output(output_content, output_file)
      end

      def analyze_directory
        coordinate_analysis(:directory) do |path, format, output_file|
          perform_directory_analysis(path, format, output_file)
        end
      end

      def parse_directory_options
        format = @parser.parse_format_option
        return {exit_code: 1} if format.nil?

        output_file = @parser.parse_output_option
        return {exit_code: 1} if output_file == :error

        {format: format, output_file: output_file, exit_code: nil}
      end

      def validate_directory_path(directory_path)
        if directory_path.nil?
          ErrorHandler.handle_missing_path_error(:directory)
          return 1
        end

        unless File.directory?(directory_path)
          ErrorHandler.handle_not_found_error(:directory, directory_path)
          1
        end
      end

      def perform_directory_analysis(directory_path, format, output_file)
        result = analyze_directory_files(directory_path)
        write_analysis_output(result, format, output_file)
        0
      rescue => e
        ErrorHandler.handle_analysis_error("directory", e)
      end

      def analyze_directory_files(directory_path)
        self.class.analyze_directory_files(directory_path)
      end

      def coordinate_analysis(analysis_type)
        path = get_path_for_analysis_type(analysis_type)
        return 1 unless validate_path_for_analysis_type(analysis_type, path)

        parse_result = parse_directory_options
        exit_code = parse_result[:exit_code]
        return exit_code if exit_code

        yield(path, parse_result[:format], parse_result[:output_file])
      end

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
          validate_file_path(path)
        when :directory
          return validate_directory_path(path) != 1 if path && File.directory?(path)
          validate_directory_path(path) != 1
        end
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
