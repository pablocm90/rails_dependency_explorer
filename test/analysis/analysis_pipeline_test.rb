# frozen_string_literal: true

require "test_helper"
require_relative "../../lib/rails_dependency_explorer/analysis/pipeline/analysis_pipeline"

# Tests for AnalysisPipeline class implementing composable analyzer architecture.
# Replaces AnalysisResult coordination with pluggable pipeline for better separation of concerns.
# Part of Phase 3.1 pipeline architecture implementation (TDD - Behavioral changes).
class AnalysisPipelineTest < Minitest::Test
  def setup
    @dependency_data = {
      "TestClass" => [{"Logger" => ["new"]}, {"DataValidator" => ["validate"]}],
      "AnotherClass" => [{"TestClass" => ["method"]}]
    }
  end

  def test_analysis_pipeline_execution
    # Test basic pipeline execution with multiple analyzers
    analyzers = [
      MockStatisticsAnalyzer.new,
      MockCircularDependencyAnalyzer.new,
      MockDepthAnalyzer.new
    ]
    
    pipeline = RailsDependencyExplorer::Analysis::Pipeline::AnalysisPipeline.new(analyzers)
    results = pipeline.analyze(@dependency_data)
    
    # Should execute all analyzers and collect results
    assert_includes results.keys, :statistics
    assert_includes results.keys, :circular_dependencies
    assert_includes results.keys, :dependency_depth
    
    # Verify analyzer execution
    assert analyzers[0].executed
    assert analyzers[1].executed
    assert analyzers[2].executed
  end

  def test_analysis_pipeline_error_handling
    # Test pipeline error handling for failing analyzers
    failing_analyzer = MockFailingAnalyzer.new
    working_analyzer = MockStatisticsAnalyzer.new
    
    pipeline = RailsDependencyExplorer::Analysis::Pipeline::AnalysisPipeline.new([failing_analyzer, working_analyzer])
    results = pipeline.analyze(@dependency_data)
    
    # Should handle analyzer failures gracefully
    assert_includes results.keys, :errors
    # Error should now be a structured error object, not a string
    error = results[:errors].first
    assert_kind_of Hash, error
    assert_includes error.keys, :error
    assert_equal "MockFailingAnalyzer execution failed", error[:error][:message]
    
    # Should still execute working analyzers
    assert_includes results.keys, :statistics
    assert working_analyzer.executed
  end

  def test_analysis_pipeline_empty_analyzers
    # Test pipeline with no analyzers
    pipeline = RailsDependencyExplorer::Analysis::Pipeline::AnalysisPipeline.new([])
    results = pipeline.analyze(@dependency_data)
    
    # Should return empty results without errors
    assert_kind_of Hash, results
    refute_includes results.keys, :errors
  end

  def test_analysis_pipeline_with_analyzer_registry
    # Test pipeline creation from analyzer registry
    registry = RailsDependencyExplorer::Analysis::Pipeline::AnalyzerRegistry.new
    registry.register(:statistics, MockStatisticsAnalyzer)
    registry.register(:circular, MockCircularDependencyAnalyzer)
    
    pipeline = RailsDependencyExplorer::Analysis::Pipeline::AnalysisPipeline.from_registry(registry)
    results = pipeline.analyze(@dependency_data)
    
    # Should create analyzers from registry and execute them
    assert_includes results.keys, :statistics
    assert_includes results.keys, :circular_dependencies
  end

  def test_analysis_pipeline_analyzer_ordering
    # Test that analyzers execute in specified order
    execution_order = []
    
    analyzer1 = MockOrderedAnalyzer.new("first", execution_order)
    analyzer2 = MockOrderedAnalyzer.new("second", execution_order)
    analyzer3 = MockOrderedAnalyzer.new("third", execution_order)
    
    pipeline = RailsDependencyExplorer::Analysis::Pipeline::AnalysisPipeline.new([analyzer1, analyzer2, analyzer3])
    pipeline.analyze(@dependency_data)
    
    # Should execute in specified order
    assert_equal ["first", "second", "third"], execution_order
  end

  def test_analysis_pipeline_result_aggregation
    # Test that pipeline properly aggregates results from multiple analyzers
    analyzer1 = MockResultAnalyzer.new(:key1, "value1")
    analyzer2 = MockResultAnalyzer.new(:key2, "value2")
    
    pipeline = RailsDependencyExplorer::Analysis::Pipeline::AnalysisPipeline.new([analyzer1, analyzer2])
    results = pipeline.analyze(@dependency_data)
    
    # Should aggregate all analyzer results under their analyzer keys
    assert_equal({ key1: "value1" }, results[:key1])
    assert_equal({ key2: "value2" }, results[:key2])
  end

  def test_analysis_pipeline_with_dependency_injection
    # Test pipeline with dependency injection container
    container = RailsDependencyExplorer::Analysis::Configuration::DependencyContainer.new
    container.register(:mock_analyzer) { |data| MockStatisticsAnalyzer.new }
    
    pipeline = RailsDependencyExplorer::Analysis::Pipeline::AnalysisPipeline.new([], container: container)
    pipeline.add_analyzer_from_container(:mock_analyzer)
    
    results = pipeline.analyze(@dependency_data)
    
    # Should use analyzer from container
    assert_includes results.keys, :statistics
  end

  def test_analysis_pipeline_configuration
    # Test pipeline configuration options
    config = {
      parallel_execution: false,
      error_handling: :continue,
      timeout: 30
    }
    
    pipeline = RailsDependencyExplorer::Analysis::Pipeline::AnalysisPipeline.new([], config: config)
    
    # Should store configuration
    assert_equal false, pipeline.config[:parallel_execution]
    assert_equal :continue, pipeline.config[:error_handling]
    assert_equal 30, pipeline.config[:timeout]
  end

  private

  # Mock analyzer classes for testing
  class MockStatisticsAnalyzer
    attr_reader :executed

    def initialize
      @executed = false
    end

    def analyze(dependency_data)
      @executed = true
      { statistics: { total_classes: dependency_data.keys.length } }
    end

    def analyzer_key
      :statistics
    end
  end

  class MockCircularDependencyAnalyzer
    attr_reader :executed

    def initialize
      @executed = false
    end

    def analyze(dependency_data)
      @executed = true
      { circular_dependencies: [] }
    end

    def analyzer_key
      :circular_dependencies
    end
  end

  class MockDepthAnalyzer
    attr_reader :executed

    def initialize
      @executed = false
    end

    def analyze(dependency_data)
      @executed = true
      { dependency_depth: { "TestClass" => 1 } }
    end

    def analyzer_key
      :dependency_depth
    end
  end

  class MockFailingAnalyzer
    def analyze(dependency_data)
      raise StandardError, "MockFailingAnalyzer execution failed"
    end

    def analyzer_key
      :failing
    end
  end

  class MockOrderedAnalyzer
    def initialize(name, execution_order)
      @name = name
      @execution_order = execution_order
    end

    def analyze(dependency_data)
      @execution_order << @name
      { @name.to_sym => "executed" }
    end

    def analyzer_key
      @name.to_sym
    end
  end

  class MockResultAnalyzer
    def initialize(key, value)
      @key = key
      @value = value
    end

    def analyze(dependency_data)
      { @key => @value }
    end

    def analyzer_key
      @key
    end
  end
end
