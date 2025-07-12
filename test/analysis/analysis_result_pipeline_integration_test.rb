# frozen_string_literal: true

require "test_helper"

# Tests for AnalysisResult pipeline integration.
# Verifies that AnalysisResult can use pipeline architecture internally while maintaining backward compatibility.
# Part of Phase 3.1 pipeline architecture implementation (TDD - Behavioral changes).
class AnalysisResultPipelineIntegrationTest < Minitest::Test
  def setup
    @dependency_data = {
      "TestClass" => [{"Logger" => ["new"]}, {"DataValidator" => ["validate"]}],
      "AnotherClass" => [{"TestClass" => ["method"]}]
    }
  end

  def test_analysis_result_create_with_pipeline_flag
    # Test creating AnalysisResult with pipeline architecture
    result = RailsDependencyExplorer::Analysis::AnalysisResult.create(@dependency_data, use_pipeline: true)
    
    # Should create AnalysisResult instance
    assert_instance_of RailsDependencyExplorer::Analysis::AnalysisResult, result
    
    # Should respond to all expected methods
    assert_respond_to result, :statistics
    assert_respond_to result, :circular_dependencies
    assert_respond_to result, :dependency_depth
    assert_respond_to result, :rails_components
    assert_respond_to result, :activerecord_relationships
    assert_respond_to result, :cross_namespace_cycles
  end

  def test_analysis_result_create_with_pipeline_produces_results
    # Test that pipeline-created AnalysisResult produces actual analysis results
    result = RailsDependencyExplorer::Analysis::AnalysisResult.create(@dependency_data, use_pipeline: true)
    
    # Should produce statistics
    statistics = result.statistics
    assert_kind_of Hash, statistics
    
    # Should produce circular dependencies
    circular_deps = result.circular_dependencies
    assert_kind_of Array, circular_deps
    
    # Should produce dependency depth
    depth = result.dependency_depth
    assert_kind_of Hash, depth
    
    # Should produce rails components
    components = result.rails_components
    assert_kind_of Hash, components
  end

  def test_analysis_result_backward_compatibility_without_pipeline
    # Test that existing AnalysisResult creation still works (backward compatibility)
    result = RailsDependencyExplorer::Analysis::AnalysisResult.create(@dependency_data)
    
    # Should create AnalysisResult instance
    assert_instance_of RailsDependencyExplorer::Analysis::AnalysisResult, result
    
    # Should respond to all expected methods
    assert_respond_to result, :statistics
    assert_respond_to result, :circular_dependencies
    assert_respond_to result, :dependency_depth
    assert_respond_to result, :rails_components
  end

  def test_analysis_result_pipeline_vs_traditional_consistency
    # Test that pipeline and traditional approaches produce consistent results
    traditional_result = RailsDependencyExplorer::Analysis::AnalysisResult.create(@dependency_data)
    pipeline_result = RailsDependencyExplorer::Analysis::AnalysisResult.create(@dependency_data, use_pipeline: true)
    
    # Statistics should be consistent
    assert_equal traditional_result.statistics.keys.sort, pipeline_result.statistics.keys.sort
    
    # Circular dependencies should be consistent
    assert_equal traditional_result.circular_dependencies, pipeline_result.circular_dependencies
    
    # Rails components structure should be consistent
    assert_equal traditional_result.rails_components.keys.sort, pipeline_result.rails_components.keys.sort
  end

  def test_analysis_result_pipeline_with_container
    # Test pipeline with dependency injection container
    container = RailsDependencyExplorer::Analysis::DependencyContainer.new
    
    result = RailsDependencyExplorer::Analysis::AnalysisResult.create(@dependency_data, container: container, use_pipeline: true)
    
    # Should create result successfully
    assert_instance_of RailsDependencyExplorer::Analysis::AnalysisResult, result
    
    # Should produce expected results
    assert_respond_to result, :statistics
    assert_respond_to result, :circular_dependencies
  end

  def test_analysis_result_pipeline_error_handling
    # Test that pipeline handles errors gracefully
    result = RailsDependencyExplorer::Analysis::AnalysisResult.create(@dependency_data, use_pipeline: true)
    
    # Should have errors method available
    assert_respond_to result, :errors
    
    # Errors should be an array
    errors = result.errors
    assert_kind_of Array, errors
  end

  def test_analysis_result_pipeline_metadata
    # Test that pipeline results include metadata
    result = RailsDependencyExplorer::Analysis::AnalysisResult.create(@dependency_data, use_pipeline: true)
    
    # Should have metadata method available
    assert_respond_to result, :metadata
    
    # Metadata should be a hash
    metadata = result.metadata
    assert_kind_of Hash, metadata
  end

  def test_analysis_result_create_with_pipeline_factory_method
    # Test the dedicated pipeline factory method
    result = RailsDependencyExplorer::Analysis::AnalysisResult.create_with_pipeline(@dependency_data)
    
    # Should create AnalysisResult instance
    assert_instance_of RailsDependencyExplorer::Analysis::AnalysisResult, result
    
    # Should have pipeline-specific methods
    assert_respond_to result, :errors
    assert_respond_to result, :metadata
    
    # Should produce analysis results
    assert_kind_of Hash, result.statistics
    assert_kind_of Array, result.circular_dependencies
  end

  def test_analysis_result_output_methods_work_with_pipeline
    # Test that output formatting methods work with pipeline results
    result = RailsDependencyExplorer::Analysis::AnalysisResult.create(@dependency_data, use_pipeline: true)
    
    # Should respond to output methods
    assert_respond_to result, :to_json
    assert_respond_to result, :to_dot
    assert_respond_to result, :to_console
    assert_respond_to result, :to_html
    assert_respond_to result, :to_csv
    
    # Should be able to call output methods without errors
    assert_kind_of String, result.to_json
    assert_kind_of String, result.to_console
  end
end
