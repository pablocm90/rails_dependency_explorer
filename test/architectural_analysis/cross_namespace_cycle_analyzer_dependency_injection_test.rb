# frozen_string_literal: true

require "test_helper"

# Tests for CrossNamespaceCycleAnalyzer dependency injection functionality.
# Ensures proper constructor injection of circular dependency analyzer and interface compliance.
# Part of Phase 2.3 cross-module dependency injection implementation (TDD - Behavioral changes).
class CrossNamespaceCycleAnalyzerDependencyInjectionTest < Minitest::Test
  def setup
    @dependency_data = {
      "App::Models::User" => [{"Services::UserService" => ["validate"]}],
      "Services::UserService" => [{"App::Models::User" => ["find"]}]
    }
  end

  def test_cross_namespace_analyzer_constructor_injection
    # Test constructor injection with custom circular analyzer
    mock_circular_analyzer = create_mock_circular_analyzer
    
    analyzer = RailsDependencyExplorer::ArchitecturalAnalysis::CrossNamespaceCycleAnalyzer.new(
      @dependency_data, 
      circular_analyzer: mock_circular_analyzer
    )
    
    # Should use injected analyzer
    result = analyzer.find_cross_namespace_cycles
    
    # Verify the mock was called
    assert mock_circular_analyzer.find_cycles_called
    expected_result = [{
      cycle: ["App::Models::User", "Services::UserService", "App::Models::User"],
      namespaces: ["App::Models", "Services"],
      severity: "high"
    }]
    assert_equal expected_result, result
  end

  def test_cross_namespace_analyzer_backward_compatibility
    # Test that old API still works without circular_analyzer parameter
    analyzer = RailsDependencyExplorer::ArchitecturalAnalysis::CrossNamespaceCycleAnalyzer.new(@dependency_data)
    
    result = analyzer.find_cross_namespace_cycles
    
    # Should create default circular analyzer and work correctly
    assert_kind_of Array, result
    refute_empty result
  end

  def test_cross_namespace_analyzer_with_cycle_detection_interface
    # Test that injected analyzer must implement CycleDetectionInterface
    mock_analyzer = MockCycleDetectionAnalyzer.new
    
    analyzer = RailsDependencyExplorer::ArchitecturalAnalysis::CrossNamespaceCycleAnalyzer.new(
      @dependency_data,
      circular_analyzer: mock_analyzer
    )
    
    result = analyzer.find_cross_namespace_cycles
    
    # Should work with any object that implements find_cycles
    assert mock_analyzer.find_cycles_called
    expected_result = [{
      cycle: ["App::Models::User", "Services::UserService", "App::Models::User"],
      namespaces: ["App::Models", "Services"],
      severity: "high"
    }]
    assert_equal expected_result, result
  end

  def test_cross_namespace_analyzer_invalid_circular_analyzer
    # Test error handling for invalid circular analyzer
    invalid_analyzer = "not_an_analyzer"
    
    assert_raises(ArgumentError) do
      RailsDependencyExplorer::ArchitecturalAnalysis::CrossNamespaceCycleAnalyzer.new(
        @dependency_data,
        circular_analyzer: invalid_analyzer
      )
    end
  end

  def test_cross_namespace_analyzer_nil_circular_analyzer
    # Test that nil circular_analyzer parameter works like no parameter
    analyzer = RailsDependencyExplorer::ArchitecturalAnalysis::CrossNamespaceCycleAnalyzer.new(
      @dependency_data,
      circular_analyzer: nil
    )
    
    result = analyzer.find_cross_namespace_cycles
    
    # Should create default circular analyzer
    assert_kind_of Array, result
  end

  def test_cross_namespace_analyzer_factory_method
    # Test factory method for creating analyzer with default circular analyzer
    analyzer = RailsDependencyExplorer::ArchitecturalAnalysis::CrossNamespaceCycleAnalyzer.create(@dependency_data)
    
    result = analyzer.find_cross_namespace_cycles
    
    # Should work with default analyzer
    assert_kind_of Array, result
  end

  def test_cross_namespace_analyzer_factory_with_container
    # Test factory method with dependency container
    container = RailsDependencyExplorer::Analysis::Configuration::DependencyContainer.new
    
    # Register custom circular analyzer in container
    container.register(:circular_analyzer) { |data| create_mock_circular_analyzer }
    
    analyzer = RailsDependencyExplorer::ArchitecturalAnalysis::CrossNamespaceCycleAnalyzer.create(
      @dependency_data,
      container: container
    )
    
    result = analyzer.find_cross_namespace_cycles
    
    # Should use analyzer from container
    expected_result = [{
      cycle: ["App::Models::User", "Services::UserService", "App::Models::User"],
      namespaces: ["App::Models", "Services"],
      severity: "high"
    }]
    assert_equal expected_result, result
  end

  private

  def create_mock_circular_analyzer
    MockCircularAnalyzer.new
  end

  # Mock analyzer classes for testing
  class MockCircularAnalyzer
    attr_reader :find_cycles_called

    def initialize
      @find_cycles_called = false
    end

    def find_cycles
      @find_cycles_called = true
      [["App::Models::User", "Services::UserService", "App::Models::User"]]
    end
  end

  class MockCycleDetectionAnalyzer
    attr_reader :find_cycles_called

    def initialize
      @find_cycles_called = false
    end

    def find_cycles
      @find_cycles_called = true
      [["App::Models::User", "Services::UserService", "App::Models::User"]]
    end
  end
end
