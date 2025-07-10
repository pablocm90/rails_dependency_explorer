# frozen_string_literal: true

require_relative "error_handler"

module RailsDependencyExplorer
  module CLI
    # Handles path validation for file and directory analysis operations.
    # Separates path validation concerns from main command coordination,
    # following SRP. Extracted from AnalyzeCommand as part of H3 refactoring.
    class PathValidator
      def validate_file_path(file_path)
        return false unless check_file_path_provided(file_path)
        return false unless check_file_exists(file_path)
        true
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

      private

      def check_file_path_provided(file_path)
        return true unless file_path.nil?
        ErrorHandler.handle_missing_path_error(:file)
        false
      end

      def check_file_exists(file_path)
        return true if File.exist?(file_path)
        ErrorHandler.handle_not_found_error(:file, file_path)
        false
      end
    end
  end
end
