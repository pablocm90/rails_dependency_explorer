# frozen_string_literal: true

require_relative "../error_handler"

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
          puts "Error: --directory option requires a directory path"
          return 1
        end

        unless File.directory?(directory_path)
          puts "Error: Directory not found: #{directory_path}"
          1
        end
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
    end
  end
end
