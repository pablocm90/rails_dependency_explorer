# frozen_string_literal: true

require_relative "dependency_parser"
require_relative "analysis_result"

module RailsDependencyExplorer
  class DependencyExplorer
    def analyze_code(ruby_code)
      dependency_data = parse_ruby_code(ruby_code)
      AnalysisResult.new(dependency_data)
    end

    def analyze_files(files)
      combined_dependency_data = {}

      files.each do |_filename, ruby_code|
        file_dependencies = parse_ruby_code(ruby_code)
        combined_dependency_data.merge!(file_dependencies)
      end

      AnalysisResult.new(combined_dependency_data)
    end

    private

    def parse_ruby_code(ruby_code)
      parser = DependencyParser.new(ruby_code)
      parser.parse
    end
  end
end
