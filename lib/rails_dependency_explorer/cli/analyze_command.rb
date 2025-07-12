# frozen_string_literal: true

require_relative "../analysis/dependency_explorer"
require_relative "error_handler"
require_relative "analysis_coordinator"

module RailsDependencyExplorer
  # CLI module provides command-line interface functionality for the Rails dependency explorer.
  # Handles user interaction, command parsing, option processing, and coordinates analysis execution.
  # Separates command-line concerns from core analysis logic following separation of concerns.
  module CLI
    # Handles the 'analyze' command for the Rails dependency explorer CLI.
    # Delegates to AnalysisCoordinator for coordination logic, maintaining
    # backward compatibility while separating concerns following SRP.
    # Refactored as part of H3 to separate complex coordination logic.
    class AnalyzeCommand
      def initialize(parser, output_writer)
        @parser = parser
        @output_writer = output_writer
        @coordinator = AnalysisCoordinator.new(parser, output_writer)
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
        @coordinator.coordinate_analysis(:file)
      end

      def analyze_directory
        @coordinator.coordinate_analysis(:directory)
      end

      # Backward compatibility methods - delegate to coordinator
      def analyze_single_file(file_path)
        @coordinator.analysis_executor.analyze_single_file(file_path)
      end

      def analyze_directory_files(directory_path)
        @coordinator.analysis_executor.analyze_directory_files(directory_path)
      end
    end
  end
end
