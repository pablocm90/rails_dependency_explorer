# frozen_string_literal: true

require 'test_helper'
require_relative '../../lib/rails_dependency_explorer/analysis/rails_component_analyzer'
require_relative '../../lib/rails_dependency_explorer/analysis/base_analyzer'

class RailsComponentAnalyzerMigrationTest < Minitest::Test
  def setup
    @dependency_data = {
      "UsersController" => [{"ApplicationController" => [[]]}],
      "User" => [{"ApplicationRecord" => [[]]}],
      "UserService" => [],
      "UserRepository" => []
    }
  end

  def test_rails_component_analyzer_inherits_from_base_analyzer
    analyzer = RailsDependencyExplorer::Analysis::RailsComponentAnalyzer.new(@dependency_data)
    
    # Should inherit from BaseAnalyzer
    assert_includes analyzer.class.ancestors, RailsDependencyExplorer::Analysis::BaseAnalyzer
  end

  def test_rails_component_analyzer_maintains_existing_api
    analyzer = RailsDependencyExplorer::Analysis::RailsComponentAnalyzer.new(@dependency_data, include_metadata: false)
    
    # Should still respond to existing methods
    assert_respond_to analyzer, :categorize_components
    assert_respond_to analyzer, :analyze

    # Both methods should return same result when metadata is disabled
    components_result = analyzer.categorize_components
    analyze_result = analyzer.analyze

    assert_equal components_result, analyze_result
  end

  def test_rails_component_analyzer_supports_base_analyzer_options
    # Should support error handling options
    analyzer = RailsDependencyExplorer::Analysis::RailsComponentAnalyzer.new(
      @dependency_data, 
      error_handling: :strict,
      include_metadata: false
    )
    
    assert_equal :strict, analyzer.options[:error_handling]
    assert_equal false, analyzer.options[:include_metadata]
  end

  def test_rails_component_analyzer_provides_metadata_when_requested
    analyzer = RailsDependencyExplorer::Analysis::RailsComponentAnalyzer.new(
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
    assert_equal "RailsDependencyExplorer::Analysis::RailsComponentAnalyzer", metadata[:analyzer_class]
    assert_equal 4, metadata[:dependency_count]
    assert_kind_of Time, metadata[:analysis_timestamp]
  end

  def test_rails_component_analyzer_returns_raw_result_without_metadata
    analyzer = RailsDependencyExplorer::Analysis::RailsComponentAnalyzer.new(
      @dependency_data, 
      include_metadata: false
    )
    
    result = analyzer.analyze
    
    # Should return raw component analysis result (hash with component categories)
    assert_kind_of Hash, result
    
    # Should contain component categories
    assert_includes result.keys, :controllers
    assert_includes result.keys, :models
    assert_includes result.keys, :services
    
    # Should not include metadata wrapper
    refute_includes result.keys, :result
    refute_includes result.keys, :metadata
  end

  def test_rails_component_analyzer_handles_errors_gracefully
    # Test with invalid dependency data
    analyzer = RailsDependencyExplorer::Analysis::RailsComponentAnalyzer.new(
      nil, 
      error_handling: :graceful
    )
    
    result = analyzer.analyze
    
    # Should return error result instead of raising
    assert_kind_of Hash, result
    assert_includes result.keys, :error
    assert_equal "Invalid dependency data provided to analyzer", result[:error][:message]
  end

  def test_rails_component_analyzer_raises_errors_in_strict_mode
    # Test with invalid dependency data
    analyzer = RailsDependencyExplorer::Analysis::RailsComponentAnalyzer.new(
      nil, 
      error_handling: :strict,
      validate_on_init: false  # Don't validate on init to test analyze-time validation
    )
    
    # Should raise error in strict mode
    assert_raises(StandardError) do
      analyzer.analyze
    end
  end

  def test_rails_component_analyzer_maintains_backward_compatibility
    analyzer = RailsDependencyExplorer::Analysis::RailsComponentAnalyzer.new(@dependency_data)
    
    # Should maintain existing categorize_components behavior
    components = analyzer.categorize_components
    
    # Should categorize Rails components correctly
    assert_kind_of Hash, components
    assert_includes components.keys, :controllers
    assert_includes components.keys, :models
    assert_includes components.keys, :services
    
    # Should identify controller
    assert_includes components[:controllers], "UsersController"

    # Should identify model
    assert_includes components[:models], "User"

    # Should identify services
    assert_includes components[:services], "UserService"
  end

  def test_rails_component_analyzer_implements_perform_analysis
    analyzer = RailsDependencyExplorer::Analysis::RailsComponentAnalyzer.new(@dependency_data)
    
    # Should implement perform_analysis method
    assert_respond_to analyzer, :perform_analysis
    
    # perform_analysis should return same result as categorize_components
    perform_result = analyzer.perform_analysis
    components_result = analyzer.categorize_components

    assert_equal components_result, perform_result
  end

  def test_rails_component_analyzer_maintains_component_categorization
    analyzer = RailsDependencyExplorer::Analysis::RailsComponentAnalyzer.new(@dependency_data)

    # Should still be able to categorize components
    assert_respond_to analyzer, :categorize_components

    components = analyzer.categorize_components
    assert_kind_of Hash, components
    assert_includes components.keys, :controllers
    assert_includes components.keys, :models
    assert_includes components.keys, :services
  end
end
