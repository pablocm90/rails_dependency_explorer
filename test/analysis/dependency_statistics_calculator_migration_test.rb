# frozen_string_literal: true

require 'test_helper'
require_relative '../../lib/rails_dependency_explorer/analysis/analyzers/dependency_statistics_calculator'
require_relative '../../lib/rails_dependency_explorer/analysis/base_analyzer'

class DependencyStatisticsCalculatorMigrationTest < Minitest::Test
  def setup
    @dependency_data = {
      "Player" => [{"Weapon" => ["damage"]}, {"Health" => ["decrease"]}],
      "Enemy" => [{"Weapon" => ["damage"]}]
    }
  end

  def test_statistics_calculator_inherits_from_base_analyzer
    calculator = RailsDependencyExplorer::Analysis::Analyzers::DependencyStatisticsCalculator.new(@dependency_data)
    
    # Should inherit from BaseAnalyzer
    assert_includes calculator.class.ancestors, RailsDependencyExplorer::Analysis::BaseAnalyzer
  end

  def test_statistics_calculator_maintains_existing_api
    calculator = RailsDependencyExplorer::Analysis::Analyzers::DependencyStatisticsCalculator.new(@dependency_data, include_metadata: false)

    # Should still respond to existing methods
    assert_respond_to calculator, :calculate_statistics
    assert_respond_to calculator, :analyze

    # Both methods should return same result when metadata is disabled
    stats_result = calculator.calculate_statistics
    analyze_result = calculator.analyze

    assert_equal stats_result, analyze_result
  end

  def test_statistics_calculator_supports_base_analyzer_options
    # Should support error handling options
    calculator = RailsDependencyExplorer::Analysis::Analyzers::DependencyStatisticsCalculator.new(
      @dependency_data, 
      error_handling: :strict,
      include_metadata: false
    )
    
    assert_equal :strict, calculator.options[:error_handling]
    assert_equal false, calculator.options[:include_metadata]
  end

  def test_statistics_calculator_provides_metadata_when_requested
    calculator = RailsDependencyExplorer::Analysis::Analyzers::DependencyStatisticsCalculator.new(
      @dependency_data, 
      include_metadata: true
    )
    
    result = calculator.analyze
    
    # Should include metadata wrapper
    assert_kind_of Hash, result
    assert_includes result.keys, :result
    assert_includes result.keys, :metadata
    
    # Metadata should include analyzer information
    metadata = result[:metadata]
    assert_equal "RailsDependencyExplorer::Analysis::Analyzers::DependencyStatisticsCalculator", metadata[:analyzer_class]
    assert_equal 2, metadata[:dependency_count]
    assert_kind_of Time, metadata[:analysis_timestamp]
  end

  def test_statistics_calculator_returns_raw_result_without_metadata
    calculator = RailsDependencyExplorer::Analysis::Analyzers::DependencyStatisticsCalculator.new(
      @dependency_data, 
      include_metadata: false
    )
    
    result = calculator.analyze
    
    # Should return raw statistics result
    assert_kind_of Hash, result
    assert_includes result.keys, :total_classes
    assert_includes result.keys, :total_dependencies
    assert_includes result.keys, :most_used_dependency
    assert_includes result.keys, :dependency_counts
    
    # Should not include metadata wrapper
    refute_includes result.keys, :result
    refute_includes result.keys, :metadata
  end

  def test_statistics_calculator_handles_errors_gracefully
    # Test with invalid dependency data
    calculator = RailsDependencyExplorer::Analysis::Analyzers::DependencyStatisticsCalculator.new(
      nil, 
      error_handling: :graceful
    )
    
    result = calculator.analyze
    
    # Should return error result instead of raising
    assert_kind_of Hash, result
    assert_includes result.keys, :error
    assert_equal "Invalid dependency data provided to analyzer", result[:error][:message]
  end

  def test_statistics_calculator_raises_errors_in_strict_mode
    # Test with invalid dependency data
    calculator = RailsDependencyExplorer::Analysis::Analyzers::DependencyStatisticsCalculator.new(
      nil, 
      error_handling: :strict,
      validate_on_init: false  # Don't validate on init to test analyze-time validation
    )
    
    # Should raise error in strict mode
    assert_raises(StandardError) do
      calculator.analyze
    end
  end

  def test_statistics_calculator_maintains_backward_compatibility
    calculator = RailsDependencyExplorer::Analysis::Analyzers::DependencyStatisticsCalculator.new(@dependency_data)
    
    # Should maintain existing calculate_statistics behavior
    stats = calculator.calculate_statistics
    
    assert_equal 2, stats[:total_classes]
    assert_equal 2, stats[:total_dependencies]
    assert_equal "Weapon", stats[:most_used_dependency]
    
    expected_counts = {"Weapon" => 2, "Health" => 1}
    assert_equal expected_counts, stats[:dependency_counts]
  end

  def test_statistics_calculator_implements_perform_analysis
    calculator = RailsDependencyExplorer::Analysis::Analyzers::DependencyStatisticsCalculator.new(@dependency_data)
    
    # Should implement perform_analysis method
    assert_respond_to calculator, :perform_analysis
    
    # perform_analysis should return same result as calculate_statistics
    perform_result = calculator.perform_analysis
    calculate_result = calculator.calculate_statistics
    
    assert_equal calculate_result, perform_result
  end
end
