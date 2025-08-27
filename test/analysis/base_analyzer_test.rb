# frozen_string_literal: true

require 'test_helper'
require_relative '../../lib/rails_dependency_explorer/analysis/base_analyzer'

class BaseAnalyzerTest < Minitest::Test
  def setup
    @dependency_data = {
      "TestClass" => [{"TestDependency" => ["method1"]}],
      "AnotherClass" => [{"TestClass" => ["method2"]}]
    }
  end

  def test_base_analyzer_provides_common_initialization
    analyzer = RailsDependencyExplorer::Analysis::BaseAnalyzer.new(@dependency_data)
    
    assert_equal @dependency_data, analyzer.dependency_data
  end

  def test_base_analyzer_implements_analyzer_interface
    analyzer = RailsDependencyExplorer::Analysis::BaseAnalyzer.new(@dependency_data)
    
    # Should include AnalyzerInterface
    assert_includes analyzer.class.ancestors, RailsDependencyExplorer::Analysis::Interfaces::AnalyzerInterface
  end

  def test_base_analyzer_provides_default_analyze_implementation
    analyzer = RailsDependencyExplorer::Analysis::BaseAnalyzer.new(@dependency_data, include_metadata: false)

    # Should call perform_analysis by default
    def analyzer.perform_analysis
      { base_analysis: "performed" }
    end

    result = analyzer.analyze
    assert_equal({ base_analysis: "performed" }, result)
  end

  def test_base_analyzer_requires_subclasses_to_implement_perform_analysis
    analyzer = RailsDependencyExplorer::Analysis::BaseAnalyzer.new(@dependency_data)
    
    # Should raise NotImplementedError if perform_analysis not implemented
    error = assert_raises(NotImplementedError) do
      analyzer.analyze
    end
    
    assert_match(/must implement #perform_analysis/, error.message)
  end

  def test_base_analyzer_provides_common_graph_building_utilities
    analyzer = RailsDependencyExplorer::Analysis::BaseAnalyzer.new(@dependency_data)
    
    # Should provide graph building utilities
    assert_respond_to analyzer, :build_adjacency_list
    
    graph = analyzer.build_adjacency_list
    assert_kind_of Hash, graph
    assert_includes graph.keys, "TestClass"
    assert_includes graph["TestClass"], "TestDependency"
  end

  def test_base_analyzer_provides_error_handling_wrapper
    analyzer = RailsDependencyExplorer::Analysis::BaseAnalyzer.new(@dependency_data)
    
    # Mock perform_analysis to raise an error
    def analyzer.perform_analysis
      raise StandardError, "Analysis failed"
    end
    
    # Should wrap errors in analysis result
    result = analyzer.analyze
    
    assert_kind_of Hash, result
    assert_includes result.keys, :error
    assert_equal "Analysis failed", result[:error][:message]
    assert_equal "StandardError", result[:error][:type]
  end

  def test_base_analyzer_provides_metadata_support
    analyzer = RailsDependencyExplorer::Analysis::BaseAnalyzer.new(@dependency_data)
    
    # Should provide metadata about the analyzer
    metadata = analyzer.metadata
    
    assert_kind_of Hash, metadata
    assert_includes metadata.keys, :analyzer_class
    assert_includes metadata.keys, :dependency_count
    assert_includes metadata.keys, :analysis_timestamp
    
    assert_equal "RailsDependencyExplorer::Analysis::BaseAnalyzer", metadata[:analyzer_class]
    assert_equal 2, metadata[:dependency_count]
    assert_kind_of Time, metadata[:analysis_timestamp]
  end

  def test_base_analyzer_supports_configuration_options
    options = { include_metadata: false, error_handling: :strict }
    analyzer = RailsDependencyExplorer::Analysis::BaseAnalyzer.new(@dependency_data, **options)
    
    # Should store configuration options
    assert_equal false, analyzer.options[:include_metadata]
    assert_equal :strict, analyzer.options[:error_handling]
  end

  def test_base_analyzer_strict_error_handling_mode
    options = { error_handling: :strict }
    analyzer = RailsDependencyExplorer::Analysis::BaseAnalyzer.new(@dependency_data, **options)
    
    # Mock perform_analysis to raise an error
    def analyzer.perform_analysis
      raise StandardError, "Analysis failed"
    end
    
    # Should re-raise errors in strict mode
    assert_raises(StandardError) do
      analyzer.analyze
    end
  end

  def test_base_analyzer_provides_validation_utilities
    analyzer = RailsDependencyExplorer::Analysis::BaseAnalyzer.new(@dependency_data)
    
    # Should provide dependency data validation
    assert_respond_to analyzer, :validate_dependency_data
    
    # Should validate successfully with good data
    assert analyzer.validate_dependency_data
    
    # Should fail validation with bad data
    bad_analyzer = RailsDependencyExplorer::Analysis::BaseAnalyzer.new(nil)
    refute bad_analyzer.validate_dependency_data
  end

  def test_base_analyzer_provides_result_formatting_utilities
    analyzer = RailsDependencyExplorer::Analysis::BaseAnalyzer.new(@dependency_data)
    
    # Should provide result formatting utilities
    assert_respond_to analyzer, :format_result
    
    raw_result = { test: "data" }
    formatted = analyzer.format_result(raw_result)
    
    assert_kind_of Hash, formatted
    assert_includes formatted.keys, :result
    assert_includes formatted.keys, :metadata
    assert_equal raw_result, formatted[:result]
  end
end
