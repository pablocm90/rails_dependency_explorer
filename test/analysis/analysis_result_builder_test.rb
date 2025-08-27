# frozen_string_literal: true

require "test_helper"
require_relative "../../lib/rails_dependency_explorer/analysis/pipeline/analysis_result_builder"

# Tests for AnalysisResultBuilder class for composing analysis results from pipeline.
# Handles result aggregation, error collection, and AnalysisResult facade creation.
# Part of Phase 3.1 pipeline architecture implementation (TDD - Behavioral changes).
class AnalysisResultBuilderTest < Minitest::Test
  def setup
    @dependency_data = {
      "TestClass" => [{"Logger" => ["new"]}, {"DataValidator" => ["validate"]}],
      "AnotherClass" => [{"TestClass" => ["method"]}]
    }
    
    @pipeline_results = {
      statistics: { total_classes: 2, total_dependencies: 3 },
      circular_dependencies: [["TestClass", "AnotherClass", "TestClass"]],
      dependency_depth: { "TestClass" => 1, "AnotherClass" => 2 },
      rails_components: { models: ["TestClass"], controllers: [], services: [] }
    }
  end

  def test_analysis_result_builder_basic_construction
    # Test basic AnalysisResult construction from pipeline results
    builder = RailsDependencyExplorer::Analysis::Pipeline::AnalysisResultBuilder.new(@dependency_data)
    
    result = builder.build_from_pipeline_results(@pipeline_results)
    
    # Should create AnalysisResult with proper delegation
    assert_instance_of RailsDependencyExplorer::Analysis::Pipeline::AnalysisResult, result
    assert_equal @pipeline_results[:statistics], result.statistics
    assert_equal @pipeline_results[:circular_dependencies], result.circular_dependencies
    assert_equal @pipeline_results[:dependency_depth], result.dependency_depth
  end

  def test_analysis_result_builder_with_errors
    # Test builder handling pipeline results with errors
    results_with_errors = @pipeline_results.merge(
      errors: ["Analyzer X failed", "Analyzer Y timed out"]
    )
    
    builder = RailsDependencyExplorer::Analysis::Pipeline::AnalysisResultBuilder.new(@dependency_data)
    result = builder.build_from_pipeline_results(results_with_errors)
    
    # Should include error information in result
    assert_respond_to result, :errors
    assert_equal ["Analyzer X failed", "Analyzer Y timed out"], result.errors
  end

  def test_analysis_result_builder_partial_results
    # Test builder with partial results (some analyzers failed)
    partial_results = {
      statistics: { total_classes: 2 },
      errors: ["CircularDependencyAnalyzer failed"]
    }
    
    builder = RailsDependencyExplorer::Analysis::Pipeline::AnalysisResultBuilder.new(@dependency_data)
    result = builder.build_from_pipeline_results(partial_results)
    
    # Should handle partial results gracefully
    assert_equal partial_results[:statistics], result.statistics
    assert_equal [], result.circular_dependencies  # Should provide default
    assert_equal ["CircularDependencyAnalyzer failed"], result.errors
  end

  def test_analysis_result_builder_result_merging
    # Test merging multiple result sets
    builder = RailsDependencyExplorer::Analysis::Pipeline::AnalysisResultBuilder.new(@dependency_data)
    
    results1 = { statistics: { total_classes: 2 } }
    results2 = { circular_dependencies: [] }
    results3 = { dependency_depth: { "TestClass" => 1 } }
    
    merged_results = builder.merge_results([results1, results2, results3])
    
    # Should merge all results into single hash
    assert_includes merged_results.keys, :statistics
    assert_includes merged_results.keys, :circular_dependencies
    assert_includes merged_results.keys, :dependency_depth
  end

  def test_analysis_result_builder_error_aggregation
    # Test aggregation of errors from multiple analyzers
    builder = RailsDependencyExplorer::Analysis::Pipeline::AnalysisResultBuilder.new(@dependency_data)
    
    results_with_errors = [
      { statistics: { total: 1 }, errors: ["Error 1"] },
      { circular_dependencies: [], errors: ["Error 2", "Error 3"] },
      { dependency_depth: {} }  # No errors
    ]
    
    merged_results = builder.merge_results(results_with_errors)
    
    # Should aggregate all errors
    assert_equal ["Error 1", "Error 2", "Error 3"], merged_results[:errors]
  end

  def test_analysis_result_builder_default_values
    # Test builder provides sensible defaults for missing analysis results
    empty_results = {}
    
    builder = RailsDependencyExplorer::Analysis::Pipeline::AnalysisResultBuilder.new(@dependency_data)
    result = builder.build_from_pipeline_results(empty_results)
    
    # Should provide defaults for all expected methods
    assert_equal({}, result.statistics)
    assert_equal([], result.circular_dependencies)
    assert_equal({}, result.dependency_depth)
    assert_equal({ models: [], controllers: [], services: [], other: [] }, result.rails_components)
  end

  def test_analysis_result_builder_custom_result_processor
    # Test builder with custom result processing
    builder = RailsDependencyExplorer::Analysis::Pipeline::AnalysisResultBuilder.new(@dependency_data)
    
    # Add custom processor for statistics
    builder.add_result_processor(:statistics) do |stats|
      stats.merge(processed: true)
    end
    
    result = builder.build_from_pipeline_results(@pipeline_results)
    
    # Should apply custom processing
    assert_equal true, result.statistics[:processed]
    assert_equal 2, result.statistics[:total_classes]  # Original data preserved
  end

  def test_analysis_result_builder_validation
    # Test builder validates pipeline results structure
    builder = RailsDependencyExplorer::Analysis::Pipeline::AnalysisResultBuilder.new(@dependency_data)
    
    invalid_results = "not_a_hash"
    
    assert_raises(ArgumentError) do
      builder.build_from_pipeline_results(invalid_results)
    end
  end

  def test_analysis_result_builder_metadata_preservation
    # Test builder preserves metadata from pipeline execution
    results_with_metadata = @pipeline_results.merge(
      metadata: {
        execution_time: 0.5,
        analyzers_executed: 4,
        pipeline_version: "1.0"
      }
    )
    
    builder = RailsDependencyExplorer::Analysis::Pipeline::AnalysisResultBuilder.new(@dependency_data)
    result = builder.build_from_pipeline_results(results_with_metadata)
    
    # Should preserve metadata
    assert_respond_to result, :metadata
    assert_equal 0.5, result.metadata[:execution_time]
    assert_equal 4, result.metadata[:analyzers_executed]
  end

  def test_analysis_result_builder_backward_compatibility
    # Test that built results maintain backward compatibility with existing AnalysisResult API
    builder = RailsDependencyExplorer::Analysis::Pipeline::AnalysisResultBuilder.new(@dependency_data)
    result = builder.build_from_pipeline_results(@pipeline_results)
    
    # Should respond to all expected AnalysisResult methods
    assert_respond_to result, :statistics
    assert_respond_to result, :circular_dependencies
    assert_respond_to result, :dependency_depth
    assert_respond_to result, :rails_components
    assert_respond_to result, :activerecord_relationships
    assert_respond_to result, :cross_namespace_cycles
  end
end
