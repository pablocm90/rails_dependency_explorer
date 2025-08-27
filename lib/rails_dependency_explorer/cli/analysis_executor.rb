# frozen_string_literal: true

require_relative "../analysis/pipeline/dependency_explorer"
require_relative "../error_handler"

module RailsDependencyExplorer
  module CLI
    # Handles execution of file and directory analysis operations.
    # Separates analysis execution concerns from main command coordination,
    # following SRP. Extracted from AnalyzeCommand as part of H3 refactoring.
    class AnalysisExecutor
      def initialize(output_writer)
        @output_writer = output_writer
      end

      def perform_file_analysis(file_path, format, output_file, output_options)
        result = analyze_single_file(file_path)
        write_analysis_output(result, format, output_file, output_options)
        0
      rescue => e
        RailsDependencyExplorer::ErrorHandler.log_error(e, context: "AnalysisExecutor", level: :error)
        1
      end

      def perform_directory_analysis(directory_path, format, output_file, output_options)
        result = analyze_directory_files(directory_path)
        write_analysis_output(result, format, output_file, output_options)
        0
      rescue => e
        RailsDependencyExplorer::ErrorHandler.log_error(e, context: "AnalysisExecutor", level: :error)
        1
      end

      def analyze_single_file(file_path)
        ruby_code = File.read(file_path)
        explorer = Analysis::Pipeline::DependencyExplorer.new
        explorer.analyze_code(ruby_code)
      end

      def analyze_directory_files(directory_path)
        explorer = Analysis::Pipeline::DependencyExplorer.new
        explorer.analyze_directory(directory_path)
      end

      private

      def write_analysis_output(result, format, output_file, output_options)
        output_content = @output_writer.format_output(result, format, output_options)
        @output_writer.write_output(output_content, output_file)
      end
    end
  end
end
