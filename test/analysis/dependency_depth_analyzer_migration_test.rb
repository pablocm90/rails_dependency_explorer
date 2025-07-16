# frozen_string_literal: true

require 'test_helper'
require_relative '../../lib/rails_dependency_explorer/analysis/dependency_depth_analyzer'
require_relative '../../lib/rails_dependency_explorer/analysis/base_analyzer'

class DependencyDepthAnalyzerMigrationTest < Minitest::Test
  def setup
    @dependency_data = {
      "A" => [{"B" => ["method1"]}],
      "B" => [{"C" => ["method2"]}],
      "C" => []  # C has no dependencies (depth 0)
    }
  end

  def test_depth_analyzer_inherits_from_base_analyzer
    analyzer = RailsDependencyExplorer::Analysis::DependencyDepthAnalyzer.new(@dependency_data)
    
    # Should inherit from BaseAnalyzer
    assert_includes analyzer.class.ancestors, RailsDependencyExplorer::Analysis::BaseAnalyzer
  end

  def test_depth_analyzer_maintains_existing_api
    analyzer = RailsDependencyExplorer::Analysis::DependencyDepthAnalyzer.new(@dependency_data, include_metadata: false)
    
    # Should still respond to existing methods
    assert_respond_to analyzer, :calculate_depth
    assert_respond_to analyzer, :analyze
    
    # Both methods should return same result when metadata is disabled
    depth_result = analyzer.calculate_depth
    analyze_result = analyzer.analyze
    
    assert_equal depth_result, analyze_result
  end

  def test_depth_analyzer_supports_base_analyzer_options
    # Should support error handling options
    analyzer = RailsDependencyExplorer::Analysis::DependencyDepthAnalyzer.new(
      @dependency_data, 
      error_handling: :strict,
      include_metadata: false
    )
    
    assert_equal :strict, analyzer.options[:error_handling]
    assert_equal false, analyzer.options[:include_metadata]
  end

  def test_depth_analyzer_provides_metadata_when_requested
    analyzer = RailsDependencyExplorer::Analysis::DependencyDepthAnalyzer.new(
      @dependency_data, 
      include_metadata: true
    )
    
    result = analyzer.analyze
    
    # Should include metadata wrapper
    assert_kind_of Hash, result
    assert_includes result.keys, :result
    assert_includes result.keys, :metadata
    
    # Metadata should include analyzer information
    metadata = result[:metadata]
    assert_equal "RailsDependencyExplorer::Analysis::DependencyDepthAnalyzer", metadata[:analyzer_class]
    assert_equal 3, metadata[:dependency_count]
    assert_kind_of Time, metadata[:analysis_timestamp]
  end

  def test_depth_analyzer_returns_raw_result_without_metadata
    analyzer = RailsDependencyExplorer::Analysis::DependencyDepthAnalyzer.new(
      @dependency_data, 
      include_metadata: false
    )
    
    result = analyzer.analyze
    
    # Should return raw depth result (hash of class => depth)
    assert_kind_of Hash, result
    
    # Should contain depth information for each class
    assert_includes result.keys, "A"
    assert_includes result.keys, "B"
    assert_includes result.keys, "C"
    
    # Should not include metadata wrapper
    refute_includes result.keys, :result
    refute_includes result.keys, :metadata
  end

  def test_depth_analyzer_handles_errors_gracefully
    # Test with invalid dependency data
    analyzer = RailsDependencyExplorer::Analysis::DependencyDepthAnalyzer.new(
      nil, 
      error_handling: :graceful
    )
    
    result = analyzer.analyze
    
    # Should return error result instead of raising
    assert_kind_of Hash, result
    assert_includes result.keys, :error
    assert_equal "Invalid dependency data provided to analyzer", result[:error][:message]
  end

  def test_depth_analyzer_raises_errors_in_strict_mode
    # Test with invalid dependency data
    analyzer = RailsDependencyExplorer::Analysis::DependencyDepthAnalyzer.new(
      nil, 
      error_handling: :strict,
      validate_on_init: false  # Don't validate on init to test analyze-time validation
    )
    
    # Should raise error in strict mode
    assert_raises(StandardError) do
      analyzer.analyze
    end
  end

  def test_depth_analyzer_maintains_backward_compatibility
    analyzer = RailsDependencyExplorer::Analysis::DependencyDepthAnalyzer.new(@dependency_data)

    # Should maintain existing calculate_depth behavior
    depths = analyzer.calculate_depth

    # Should calculate correct depths (depth = how deep in dependency chain)
    assert_kind_of Hash, depths
    assert_equal 0, depths["A"]  # A is root level (no one depends on A)
    assert_equal 1, depths["B"]  # B is depth 1 (A depends on B)
    assert_equal 2, depths["C"]  # C is depth 2 (B depends on C, A->B->C)
  end

  def test_depth_analyzer_implements_perform_analysis
    analyzer = RailsDependencyExplorer::Analysis::DependencyDepthAnalyzer.new(@dependency_data)
    
    # Should implement perform_analysis method
    assert_respond_to analyzer, :perform_analysis
    
    # perform_analysis should return same result as calculate_depth
    perform_result = analyzer.perform_analysis
    depth_result = analyzer.calculate_depth
    
    assert_equal depth_result, perform_result
  end
end
