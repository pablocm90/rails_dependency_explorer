# frozen_string_literal: true

require_relative "../analysis/dependency_explorer"

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

      private

      def analyze_file
        file_path = @parser.get_file_path
        return 1 unless validate_file_path(file_path)

        format = @parser.parse_format_option
        return 1 if format.nil?

        output_file = @parser.parse_output_option
        return 1 if output_file == :error

        perform_file_analysis(file_path, format, output_file)
      end

      def validate_file_path(file_path)
        return false unless check_file_path_provided(file_path)
        return false unless check_file_exists(file_path)
        true
      end

      private

      def check_file_path_provided(file_path)
        return true unless file_path.nil?

        puts "Error: analyze command requires a file path"
        puts "Usage: rails_dependency_explorer analyze <path>"
        false
      end

      def check_file_exists(file_path)
        return true if File.exist?(file_path)

        puts "Error: File not found: #{file_path}"
        false
      end

      def perform_file_analysis(file_path, format, output_file)
        result = analyze_single_file(file_path)
        write_analysis_output(result, format, output_file)
        0
      rescue => e
        puts "Error analyzing file: #{e.message}"
        1
      end

      def analyze_single_file(file_path)
        self.class.analyze_single_file(file_path)
      end

      def self.analyze_single_file(file_path)
        ruby_code = File.read(file_path)
        explorer = Analysis::DependencyExplorer.new
        explorer.analyze_code(ruby_code)
      end

      def write_analysis_output(result, format, output_file)
        output_content = @output_writer.format_output(result, format, build_output_options)
        @output_writer.write_output(output_content, output_file)
      end

      def analyze_directory
        directory_path = @parser.get_directory_path
        return validate_directory_path(directory_path) unless directory_path && File.directory?(directory_path)

        format = @parser.parse_format_option
        return 1 if format.nil?

        output_file = @parser.parse_output_option
        return 1 if output_file == :error

        perform_directory_analysis(directory_path, format, output_file)
      end

      private

      def validate_directory_path(directory_path)
        if directory_path.nil?
          puts "Error: --directory option requires a directory path"
          return 1
        end

        unless File.directory?(directory_path)
          puts "Error: Directory not found: #{directory_path}"
          return 1
        end
      end

      def perform_directory_analysis(directory_path, format, output_file)
        result = analyze_directory_files(directory_path)
        write_analysis_output(result, format, output_file)
        0
      rescue => e
        puts "Error analyzing directory: #{e.message}"
        1
      end

      def analyze_directory_files(directory_path)
        self.class.analyze_directory_files(directory_path)
      end

      def self.analyze_directory_files(directory_path)
        explorer = Analysis::DependencyExplorer.new
        explorer.analyze_directory(directory_path)
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
