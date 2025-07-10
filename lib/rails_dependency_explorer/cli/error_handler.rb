# frozen_string_literal: true

module RailsDependencyExplorer
  module CLI
    # Handles error reporting and exit code management for CLI commands.
    # Provides consistent error message formatting and exception handling
    # across different analysis operations.
    class ErrorHandler
      def self.handle_analysis_error(operation_type, error)
        puts "Error analyzing #{operation_type}: #{error.message}"
        1
      end

      def self.handle_validation_error(message)
        puts "Error: #{message}"
        false
      end

      def self.handle_missing_path_error(path_type)
        case path_type
        when :file
          puts "Error: analyze command requires a file path"
          puts "Usage: rails_dependency_explorer analyze <path>"
        when :directory
          puts "Error: --directory option requires a directory path"
        end
        false
      end

      def self.handle_not_found_error(path_type, path)
        case path_type
        when :file
          puts "Error: File not found: #{path}"
        when :directory
          puts "Error: Directory not found: #{path}"
        end
        false
      end
    end
  end
end
