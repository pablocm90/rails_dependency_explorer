# frozen_string_literal: true

require_relative "../parsing/dependency_parser"
require_relative "analysis_result"

module RailsDependencyExplorer
  module Analysis
    # Main entry point for analyzing Ruby code dependencies in Rails applications.
    # Scans directories and files to extract class dependencies, method calls, and
    # constant references, building a comprehensive dependency graph.
    class DependencyExplorer
      def initialize(container: nil)
        @container = container
      end

      # Factory method for creating DependencyExplorer with dependency container
      # @param container [DependencyContainer] Optional DI container for custom analyzers
      # @return [DependencyExplorer] New instance with appropriate container
      def self.create(container: nil)
        new(container: container)
      end

      def analyze_code(ruby_code)
        dependency_data = self.class.parse_ruby_code(ruby_code)
        AnalysisResult.create(dependency_data, container: @container)
      end

      def analyze_files(files)
        combined_dependency_data = {}

        files.each do |_filename, ruby_code|
          file_dependencies = self.class.parse_ruby_code(ruby_code)
          combined_dependency_data.merge!(file_dependencies)
        end

        AnalysisResult.create(combined_dependency_data, container: @container)
      end

      def analyze_directory(directory_path, pattern: "*.rb")
        ruby_files = Dir.glob(File.join(directory_path, "**", pattern))
        files_hash = self.class.build_files_hash(ruby_files)
        analyze_files(files_hash)
      end

      def self.build_files_hash(ruby_files)
        ruby_files.each_with_object({}) do |file_path, files_hash|
          filename = File.basename(file_path)
          ruby_code = File.read(file_path)
          files_hash[filename] = ruby_code
        end
      end

      def self.parse_ruby_code(ruby_code)
        parser = Parsing::DependencyParser.new(ruby_code)
        parser.parse
      end
    end
  end
end
