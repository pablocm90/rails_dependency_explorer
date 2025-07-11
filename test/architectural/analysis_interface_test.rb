# frozen_string_literal: true

require "test_helper"

# Tests for analysis interface compliance across analyzer components.
# Ensures all analyzers implement consistent interfaces for better abstraction.
# Part of Phase 1.2 architectural refactoring (Tidy First - Structural changes only).
class AnalysisInterfaceTest < Minitest::Test
  def test_analyzer_interface_exists
    # Test that AnalyzerInterface module exists and defines required methods
    assert defined?(RailsDependencyExplorer::Analysis::AnalyzerInterface),
      "AnalyzerInterface module should be defined"
    
    interface = RailsDependencyExplorer::Analysis::AnalyzerInterface
    
    # Check that interface defines required method signatures
    assert interface.method_defined?(:analyze),
      "AnalyzerInterface should define analyze method"
  end

  def test_circular_dependency_analyzer_implements_interface
    analyzer_class = RailsDependencyExplorer::Analysis::CircularDependencyAnalyzer
    
    # Test that CircularDependencyAnalyzer includes AnalyzerInterface
    assert analyzer_class.ancestors.include?(RailsDependencyExplorer::Analysis::AnalyzerInterface),
      "CircularDependencyAnalyzer should include AnalyzerInterface"
    
    # Test that it implements the analyze method
    assert analyzer_class.method_defined?(:analyze),
      "CircularDependencyAnalyzer should implement analyze method"
  end

  def test_dependency_depth_analyzer_implements_interface
    analyzer_class = RailsDependencyExplorer::Analysis::DependencyDepthAnalyzer
    
    # Test that DependencyDepthAnalyzer includes AnalyzerInterface
    assert analyzer_class.ancestors.include?(RailsDependencyExplorer::Analysis::AnalyzerInterface),
      "DependencyDepthAnalyzer should include AnalyzerInterface"
    
    # Test that it implements the analyze method
    assert analyzer_class.method_defined?(:analyze),
      "DependencyDepthAnalyzer should implement analyze method"
  end

  def test_dependency_statistics_calculator_implements_interface
    analyzer_class = RailsDependencyExplorer::Analysis::DependencyStatisticsCalculator
    
    # Test that DependencyStatisticsCalculator includes AnalyzerInterface
    assert analyzer_class.ancestors.include?(RailsDependencyExplorer::Analysis::AnalyzerInterface),
      "DependencyStatisticsCalculator should include AnalyzerInterface"
    
    # Test that it implements the analyze method
    assert analyzer_class.method_defined?(:analyze),
      "DependencyStatisticsCalculator should implement analyze method"
  end

  def test_cycle_detection_interface_exists
    # Test that CycleDetectionInterface module exists
    assert defined?(RailsDependencyExplorer::Analysis::CycleDetectionInterface),
      "CycleDetectionInterface module should be defined"
    
    interface = RailsDependencyExplorer::Analysis::CycleDetectionInterface
    
    # Check that interface defines cycle detection methods
    assert interface.method_defined?(:find_cycles),
      "CycleDetectionInterface should define find_cycles method"
  end

  def test_circular_dependency_analyzer_implements_cycle_detection_interface
    analyzer_class = RailsDependencyExplorer::Analysis::CircularDependencyAnalyzer
    
    # Test that CircularDependencyAnalyzer includes CycleDetectionInterface
    assert analyzer_class.ancestors.include?(RailsDependencyExplorer::Analysis::CycleDetectionInterface),
      "CircularDependencyAnalyzer should include CycleDetectionInterface"
    
    # Test that it implements the find_cycles method
    assert analyzer_class.method_defined?(:find_cycles),
      "CircularDependencyAnalyzer should implement find_cycles method"
  end

  def test_statistics_interface_exists
    # Test that StatisticsInterface module exists
    assert defined?(RailsDependencyExplorer::Analysis::StatisticsInterface),
      "StatisticsInterface module should be defined"
    
    interface = RailsDependencyExplorer::Analysis::StatisticsInterface
    
    # Check that interface defines statistics methods
    assert interface.method_defined?(:calculate_statistics),
      "StatisticsInterface should define calculate_statistics method"
  end

  def test_dependency_statistics_calculator_implements_statistics_interface
    analyzer_class = RailsDependencyExplorer::Analysis::DependencyStatisticsCalculator
    
    # Test that DependencyStatisticsCalculator includes StatisticsInterface
    assert analyzer_class.ancestors.include?(RailsDependencyExplorer::Analysis::StatisticsInterface),
      "DependencyStatisticsCalculator should include StatisticsInterface"
    
    # Test that it implements the calculate_statistics method
    assert analyzer_class.method_defined?(:calculate_statistics),
      "DependencyStatisticsCalculator should implement calculate_statistics method"
  end

  def test_interface_segregation_principle
    # Test that interfaces are properly segregated (not too broad)
    
    # AnalyzerInterface should be minimal
    analyzer_interface = RailsDependencyExplorer::Analysis::AnalyzerInterface
    analyzer_methods = analyzer_interface.instance_methods(false)
    
    assert analyzer_methods.length <= 2,
      "AnalyzerInterface should be minimal (max 2 methods), has: #{analyzer_methods}"
    
    # CycleDetectionInterface should be focused on cycle detection
    cycle_interface = RailsDependencyExplorer::Analysis::CycleDetectionInterface
    cycle_methods = cycle_interface.instance_methods(false)
    
    assert cycle_methods.length <= 3,
      "CycleDetectionInterface should be focused (max 3 methods), has: #{cycle_methods}"
    
    # StatisticsInterface should be focused on statistics
    stats_interface = RailsDependencyExplorer::Analysis::StatisticsInterface
    stats_methods = stats_interface.instance_methods(false)
    
    assert stats_methods.length <= 3,
      "StatisticsInterface should be focused (max 3 methods), has: #{stats_methods}"
  end

  def test_interface_method_signatures
    # Test that interface methods have proper signatures (accept dependency_data)
    
    # Create test instances to verify method signatures
    dependency_data = { "TestClass" => ["TestDependency"] }
    
    # Test AnalyzerInterface compliance through CircularDependencyAnalyzer
    analyzer = RailsDependencyExplorer::Analysis::CircularDependencyAnalyzer.new(dependency_data)
    
    # Should respond to analyze method
    assert_respond_to analyzer, :analyze,
      "Analyzer should respond to analyze method"
    
    # analyze method should accept no parameters (uses instance data)
    assert_equal 0, analyzer.method(:analyze).arity,
      "analyze method should accept no parameters"
  end
end
