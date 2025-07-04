# frozen_string_literal: true

require_relative "dependency_parser"
require_relative "analysis_result"

module RailsDependencyExplorer
  class DependencyExplorer
    def analyze_code(ruby_code)
      parser = DependencyParser.new(ruby_code)
      dependency_data = parser.parse

      AnalysisResult.new(dependency_data)
    end
  end
end
