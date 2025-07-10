# frozen_string_literal: true

require "minitest/autorun"
require "json"
require_relative "../test_helper"

class DependencyExplorerParsingTest < Minitest::Test
  def setup
    @explorer = RailsDependencyExplorer::Analysis::DependencyExplorer.new
  end

  def test_dependency_explorer_detects_require_relative_dependencies
    # This test reproduces the CLI issue with our own project files
    ruby_code = <<~RUBY
      require_relative "../parsing/dependency_parser"
      require_relative "analysis_result"

      module RailsDependencyExplorer
        module Analysis
          class DependencyExplorer
            def analyze_code(ruby_code)
              dependency_data = parse_ruby_code(ruby_code)
              AnalysisResult.new(dependency_data)
            end

            private

            def parse_ruby_code(ruby_code)
              parser = Parsing::DependencyParser.new(ruby_code)
              parser.parse
            end
          end
        end
      end
    RUBY

    result = @explorer.analyze_code(ruby_code)
    graph = result.to_graph

    # Should detect class instantiations as dependencies
    assert_includes graph[:nodes], "DependencyExplorer"
    assert_includes graph[:nodes], "AnalysisResult"
    assert_includes graph[:nodes], "DependencyParser"

    # Should detect the dependency relationships
    assert_includes graph[:edges], ["DependencyExplorer", "AnalysisResult"]
    assert_includes graph[:edges], ["DependencyExplorer", "DependencyParser"]
  end

  def test_dependency_explorer_handles_code_with_modules_and_requires
    # Test simpler case to isolate the issue
    ruby_code = <<~RUBY
      require_relative "some_file"

      class SimpleClass
        def method
          OtherClass.new
        end
      end
    RUBY

    result = @explorer.analyze_code(ruby_code)
    graph = result.to_graph

    # Should detect the class and its dependency
    assert_includes graph[:nodes], "SimpleClass"
    assert_includes graph[:nodes], "OtherClass"
    assert_includes graph[:edges], ["SimpleClass", "OtherClass"]
  end
end
