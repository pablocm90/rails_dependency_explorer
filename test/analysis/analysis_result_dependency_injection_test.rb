# frozen_string_literal: true

require "test_helper"

# Tests for AnalysisResult dependency injection functionality.
# Ensures proper constructor injection, backward compatibility, and analyzer management.
# Part of Phase 2.2 dependency injection implementation (TDD - Behavioral changes).
class AnalysisResultDependencyInjectionTest < Minitest::Test
  def setup
    @dependency_data = { "TestClass" => ["Dependency1", "Dependency2"] }
  end

  def test_analysis_result_constructor_injection
    # Test constructor injection with custom analyzers
    analyzers = {
      circular_analyzer: create_mock_circular_analyzer,
      depth_analyzer: create_mock_depth_analyzer,
      statistics_calculator: create_mock_statistics_calculator,
      rails_component_analyzer: create_mock_rails_component_analyzer,
      activerecord_relationship_analyzer: create_mock_activerecord_analyzer,
      cross_namespace_cycle_analyzer: create_mock_cross_namespace_analyzer
    }
    
    result = RailsDependencyExplorer::Analysis::Pipeline::AnalysisResult.new(@dependency_data, analyzers: analyzers)
    
    # Verify injected dependencies are used
    assert_same analyzers[:circular_analyzer], result.send(:circular_analyzer)
    assert_same analyzers[:depth_analyzer], result.send(:depth_analyzer)
    assert_same analyzers[:statistics_calculator], result.send(:statistics_calculator)
    assert_same analyzers[:rails_component_analyzer], result.send(:rails_component_analyzer)
    assert_same analyzers[:activerecord_relationship_analyzer], result.send(:activerecord_relationship_analyzer)
    assert_same analyzers[:cross_namespace_cycle_analyzer], result.send(:cross_namespace_cycle_analyzer)
  end

  def test_analysis_result_partial_analyzer_injection
    # Test constructor injection with only some analyzers provided
    analyzers = {
      circular_analyzer: create_mock_circular_analyzer,
      statistics_calculator: create_mock_statistics_calculator
    }
    
    result = RailsDependencyExplorer::Analysis::Pipeline::AnalysisResult.new(@dependency_data, analyzers: analyzers)
    
    # Verify injected dependencies are used
    assert_same analyzers[:circular_analyzer], result.send(:circular_analyzer)
    assert_same analyzers[:statistics_calculator], result.send(:statistics_calculator)
    
    # Verify default analyzers are created for non-injected ones
    assert_instance_of RailsDependencyExplorer::Analysis::Analyzers::DependencyDepthAnalyzer, result.send(:depth_analyzer)
    assert_instance_of RailsDependencyExplorer::Analysis::Analyzers::RailsComponentAnalyzer, result.send(:rails_component_analyzer)
  end

  def test_analysis_result_backward_compatibility
    # Test that old API still works without analyzers parameter
    result = RailsDependencyExplorer::Analysis::Pipeline::AnalysisResult.new(@dependency_data)
    
    # Should create default analyzers
    assert_instance_of RailsDependencyExplorer::Analysis::Analyzers::CircularDependencyAnalyzer, result.send(:circular_analyzer)
    assert_instance_of RailsDependencyExplorer::Analysis::Analyzers::DependencyDepthAnalyzer, result.send(:depth_analyzer)
    assert_instance_of RailsDependencyExplorer::Analysis::Analyzers::DependencyStatisticsCalculator, result.send(:statistics_calculator)
    assert_instance_of RailsDependencyExplorer::Analysis::Analyzers::RailsComponentAnalyzer, result.send(:rails_component_analyzer)
    assert_instance_of RailsDependencyExplorer::Analysis::Analyzers::ActiveRecordRelationshipAnalyzer, result.send(:activerecord_relationship_analyzer)
    assert_instance_of RailsDependencyExplorer::ArchitecturalAnalysis::CrossNamespaceCycleAnalyzer, result.send(:cross_namespace_cycle_analyzer)
  end

  def test_analysis_result_delegated_methods_with_injection
    # Test that delegated methods work with injected analyzers
    mock_circular = create_mock_circular_analyzer
    mock_depth = create_mock_depth_analyzer
    mock_stats = create_mock_statistics_calculator
    
    analyzers = {
      circular_analyzer: mock_circular,
      depth_analyzer: mock_depth,
      statistics_calculator: mock_stats
    }
    
    result = RailsDependencyExplorer::Analysis::Pipeline::AnalysisResult.new(@dependency_data, analyzers: analyzers)
    
    # Test delegated methods call the injected analyzers
    result.circular_dependencies
    result.dependency_depth
    result.statistics
    
    # Verify the mock methods were called
    assert mock_circular.find_cycles_called
    assert mock_depth.calculate_depth_called
    assert mock_stats.calculate_statistics_called
  end

  def test_analysis_result_factory_method
    # Test factory method for creating AnalysisResult with default analyzers
    result = RailsDependencyExplorer::Analysis::Pipeline::AnalysisResult.create(@dependency_data)
    
    # Should create default analyzers
    assert_instance_of RailsDependencyExplorer::Analysis::Analyzers::CircularDependencyAnalyzer, result.send(:circular_analyzer)
    assert_instance_of RailsDependencyExplorer::Analysis::Analyzers::DependencyDepthAnalyzer, result.send(:depth_analyzer)
    assert_instance_of RailsDependencyExplorer::Analysis::Analyzers::DependencyStatisticsCalculator, result.send(:statistics_calculator)
  end

  def test_analysis_result_factory_method_with_container
    # Test factory method with dependency container
    container = RailsDependencyExplorer::Analysis::Configuration::DependencyContainer.new
    
    # Register custom analyzers in container
    container.register(:circular_analyzer) { |data| create_mock_circular_analyzer }
    container.register(:statistics_calculator) { |data| create_mock_statistics_calculator }
    
    result = RailsDependencyExplorer::Analysis::Pipeline::AnalysisResult.create(@dependency_data, container: container)
    
    # Should use analyzers from container
    assert_kind_of MockCircularAnalyzer, result.send(:circular_analyzer)
    assert_kind_of MockStatisticsCalculator, result.send(:statistics_calculator)
    
    # Should create default for non-registered analyzers
    assert_instance_of RailsDependencyExplorer::Analysis::Analyzers::DependencyDepthAnalyzer, result.send(:depth_analyzer)
  end

  def test_analysis_result_invalid_analyzer_injection
    # Test error handling for invalid analyzer types
    analyzers = {
      circular_analyzer: "not_an_analyzer"
    }
    
    assert_raises(ArgumentError) do
      RailsDependencyExplorer::Analysis::Pipeline::AnalysisResult.new(@dependency_data, analyzers: analyzers)
    end
  end

  def test_analysis_result_nil_analyzers_parameter
    # Test that nil analyzers parameter works like no parameter
    result = RailsDependencyExplorer::Analysis::Pipeline::AnalysisResult.new(@dependency_data, analyzers: nil)
    
    # Should create default analyzers
    assert_instance_of RailsDependencyExplorer::Analysis::Analyzers::CircularDependencyAnalyzer, result.send(:circular_analyzer)
    assert_instance_of RailsDependencyExplorer::Analysis::Analyzers::DependencyDepthAnalyzer, result.send(:depth_analyzer)
  end

  private

  def create_mock_circular_analyzer
    MockCircularAnalyzer.new
  end

  def create_mock_depth_analyzer
    MockDepthAnalyzer.new
  end

  def create_mock_statistics_calculator
    MockStatisticsCalculator.new
  end

  def create_mock_rails_component_analyzer
    MockRailsComponentAnalyzer.new
  end

  def create_mock_activerecord_analyzer
    MockActiveRecordAnalyzer.new
  end

  def create_mock_cross_namespace_analyzer
    MockCrossNamespaceAnalyzer.new
  end

  # Mock analyzer classes for testing
  class MockCircularAnalyzer
    attr_reader :find_cycles_called

    def initialize
      @find_cycles_called = false
    end

    def find_cycles
      @find_cycles_called = true
      []
    end
  end

  class MockDepthAnalyzer
    attr_reader :calculate_depth_called

    def initialize
      @calculate_depth_called = false
    end

    def calculate_depth
      @calculate_depth_called = true
      {}
    end
  end

  class MockStatisticsCalculator
    attr_reader :calculate_statistics_called

    def initialize
      @calculate_statistics_called = false
    end

    def calculate_statistics
      @calculate_statistics_called = true
      {}
    end
  end

  class MockRailsComponentAnalyzer
    def categorize_components
      {}
    end
  end

  class MockActiveRecordAnalyzer
    def analyze_relationships
      {}
    end
  end

  class MockCrossNamespaceAnalyzer
    def find_cross_namespace_cycles
      []
    end
  end
end
