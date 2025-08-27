# frozen_string_literal: true

require 'test_helper'
require_relative '../../lib/rails_dependency_explorer/analysis/analyzers/circular_dependency_analyzer'
require_relative '../../lib/rails_dependency_explorer/analysis/base_analyzer'

class CircularDependencyAnalyzerMigrationTest < Minitest::Test
  def setup
    @dependency_data = {
      "A" => [{"B" => ["method1"]}],
      "B" => [{"C" => ["method2"]}],
      "C" => [{"A" => ["method3"]}]  # Creates cycle A -> B -> C -> A
    }
  end

  def test_circular_analyzer_inherits_from_base_analyzer
    analyzer = RailsDependencyExplorer::Analysis::Analyzers::CircularDependencyAnalyzer.new(@dependency_data)
    
    # Should inherit from BaseAnalyzer
    assert_includes analyzer.class.ancestors, RailsDependencyExplorer::Analysis::BaseAnalyzer
  end

  def test_circular_analyzer_maintains_existing_api
    analyzer = RailsDependencyExplorer::Analysis::Analyzers::CircularDependencyAnalyzer.new(@dependency_data, include_metadata: false)
    
    # Should still respond to existing methods
    assert_respond_to analyzer, :find_cycles
    assert_respond_to analyzer, :analyze
    
    # Both methods should return same result when metadata is disabled
    cycles_result = analyzer.find_cycles
    analyze_result = analyzer.analyze
    
    assert_equal cycles_result, analyze_result
  end

  def test_circular_analyzer_supports_base_analyzer_options
    # Should support error handling options
    analyzer = RailsDependencyExplorer::Analysis::Analyzers::CircularDependencyAnalyzer.new(
      @dependency_data, 
      error_handling: :strict,
      include_metadata: false
    )
    
    assert_equal :strict, analyzer.options[:error_handling]
    assert_equal false, analyzer.options[:include_metadata]
  end

  def test_circular_analyzer_provides_metadata_when_requested
    analyzer = RailsDependencyExplorer::Analysis::Analyzers::CircularDependencyAnalyzer.new(
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
    assert_equal "RailsDependencyExplorer::Analysis::Analyzers::CircularDependencyAnalyzer", metadata[:analyzer_class]
    assert_equal 3, metadata[:dependency_count]
    assert_kind_of Time, metadata[:analysis_timestamp]
  end

  def test_circular_analyzer_returns_raw_result_without_metadata
    analyzer = RailsDependencyExplorer::Analysis::Analyzers::CircularDependencyAnalyzer.new(
      @dependency_data, 
      include_metadata: false
    )
    
    result = analyzer.analyze
    
    # Should return raw cycles result (array of cycles)
    assert_kind_of Array, result
    
    # Should not include metadata wrapper
    refute result.respond_to?(:keys) || (result.respond_to?(:keys) && result.keys.include?(:result))
  end

  def test_circular_analyzer_handles_errors_gracefully
    # Test with invalid dependency data
    analyzer = RailsDependencyExplorer::Analysis::Analyzers::CircularDependencyAnalyzer.new(
      nil, 
      error_handling: :graceful
    )
    
    result = analyzer.analyze
    
    # Should return error result instead of raising
    assert_kind_of Hash, result
    assert_includes result.keys, :error
    assert_equal "Invalid dependency data provided to analyzer", result[:error][:message]
  end

  def test_circular_analyzer_raises_errors_in_strict_mode
    # Test with invalid dependency data
    analyzer = RailsDependencyExplorer::Analysis::Analyzers::CircularDependencyAnalyzer.new(
      nil, 
      error_handling: :strict,
      validate_on_init: false  # Don't validate on init to test analyze-time validation
    )
    
    # Should raise error in strict mode
    assert_raises(StandardError) do
      analyzer.analyze
    end
  end

  def test_circular_analyzer_maintains_backward_compatibility
    analyzer = RailsDependencyExplorer::Analysis::Analyzers::CircularDependencyAnalyzer.new(@dependency_data)
    
    # Should maintain existing find_cycles behavior
    cycles = analyzer.find_cycles
    
    # Should find the circular dependency
    assert_kind_of Array, cycles
    assert_equal 1, cycles.length
    
    cycle = cycles.first
    assert_includes cycle, "A"
    assert_includes cycle, "B" 
    assert_includes cycle, "C"
  end

  def test_circular_analyzer_implements_perform_analysis
    analyzer = RailsDependencyExplorer::Analysis::Analyzers::CircularDependencyAnalyzer.new(@dependency_data)
    
    # Should implement perform_analysis method
    assert_respond_to analyzer, :perform_analysis
    
    # perform_analysis should return same result as find_cycles
    perform_result = analyzer.perform_analysis
    cycles_result = analyzer.find_cycles
    
    assert_equal cycles_result, perform_result
  end

  def test_circular_analyzer_includes_graph_analyzer_interface
    analyzer = RailsDependencyExplorer::Analysis::Analyzers::CircularDependencyAnalyzer.new(@dependency_data)

    # Should include GraphAnalyzerInterface (new interface)
    assert_includes analyzer.class.included_modules, RailsDependencyExplorer::Analysis::Interfaces::GraphAnalyzerInterface
  end
end
