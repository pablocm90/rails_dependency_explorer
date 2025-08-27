# frozen_string_literal: true

require "test_helper"

# Tests for analysis interface compliance across analyzer components.
# Ensures all analyzers implement consistent interfaces for better abstraction.
# Part of Phase 1.2 architectural refactoring (Tidy First - Structural changes only).
class AnalysisInterfaceTest < Minitest::Test
  def test_analyzer_interface_exists
    # Test that AnalyzerInterface module exists and defines required methods
    assert defined?(RailsDependencyExplorer::Analysis::Interfaces::AnalyzerInterface),
      "AnalyzerInterface module should be defined"
    
    interface = RailsDependencyExplorer::Analysis::Interfaces::AnalyzerInterface
    
    # Check that interface defines required method signatures
    assert interface.method_defined?(:analyze),
      "AnalyzerInterface should define analyze method"
  end

  def test_circular_dependency_analyzer_implements_interface
    analyzer_class = RailsDependencyExplorer::Analysis::Analyzers::CircularDependencyAnalyzer
    
    # Test that CircularDependencyAnalyzer includes AnalyzerInterface
    assert analyzer_class.ancestors.include?(RailsDependencyExplorer::Analysis::Interfaces::AnalyzerInterface),
      "CircularDependencyAnalyzer should include AnalyzerInterface"
    
    # Test that it implements the analyze method
    assert analyzer_class.method_defined?(:analyze),
      "CircularDependencyAnalyzer should implement analyze method"
  end

  def test_dependency_depth_analyzer_implements_interface
    analyzer_class = RailsDependencyExplorer::Analysis::Analyzers::DependencyDepthAnalyzer
    
    # Test that DependencyDepthAnalyzer includes AnalyzerInterface
    assert analyzer_class.ancestors.include?(RailsDependencyExplorer::Analysis::Interfaces::AnalyzerInterface),
      "DependencyDepthAnalyzer should include AnalyzerInterface"
    
    # Test that it implements the analyze method
    assert analyzer_class.method_defined?(:analyze),
      "DependencyDepthAnalyzer should implement analyze method"
  end

  def test_dependency_statistics_calculator_implements_interface
    analyzer_class = RailsDependencyExplorer::Analysis::Analyzers::DependencyStatisticsCalculator
    
    # Test that DependencyStatisticsCalculator includes AnalyzerInterface
    assert analyzer_class.ancestors.include?(RailsDependencyExplorer::Analysis::Interfaces::AnalyzerInterface),
      "DependencyStatisticsCalculator should include AnalyzerInterface"
    
    # Test that it implements the analyze method
    assert analyzer_class.method_defined?(:analyze),
      "DependencyStatisticsCalculator should implement analyze method"
  end

  def test_graph_analyzer_interface_exists
    # Test that GraphAnalyzerInterface module exists
    assert defined?(RailsDependencyExplorer::Analysis::Interfaces::GraphAnalyzerInterface),
      "GraphAnalyzerInterface module should be defined"

    interface = RailsDependencyExplorer::Analysis::Interfaces::GraphAnalyzerInterface

    # Check that interface defines graph analysis methods
    assert interface.method_defined?(:build_adjacency_list),
      "GraphAnalyzerInterface should define build_adjacency_list method"
  end

  def test_circular_dependency_analyzer_implements_graph_analyzer_interface
    analyzer_class = RailsDependencyExplorer::Analysis::Analyzers::CircularDependencyAnalyzer

    # Test that CircularDependencyAnalyzer includes GraphAnalyzerInterface
    assert analyzer_class.ancestors.include?(RailsDependencyExplorer::Analysis::Interfaces::GraphAnalyzerInterface),
      "CircularDependencyAnalyzer should include GraphAnalyzerInterface"

    # Test that it implements the find_cycles method
    assert analyzer_class.method_defined?(:find_cycles),
      "CircularDependencyAnalyzer should implement find_cycles method"
  end

  def test_statistics_analyzer_interface_exists
    # Test that StatisticsAnalyzerInterface module exists
    assert defined?(RailsDependencyExplorer::Analysis::Interfaces::StatisticsAnalyzerInterface),
      "StatisticsAnalyzerInterface module should be defined"

    interface = RailsDependencyExplorer::Analysis::Interfaces::StatisticsAnalyzerInterface

    # Check that interface defines statistics methods
    assert interface.method_defined?(:calculate_basic_statistics),
      "StatisticsAnalyzerInterface should define calculate_basic_statistics method"
  end

  def test_dependency_statistics_calculator_implements_statistics_analyzer_interface
    analyzer_class = RailsDependencyExplorer::Analysis::Analyzers::DependencyStatisticsCalculator

    # Test that DependencyStatisticsCalculator includes StatisticsAnalyzerInterface
    assert analyzer_class.ancestors.include?(RailsDependencyExplorer::Analysis::Interfaces::StatisticsAnalyzerInterface),
      "DependencyStatisticsCalculator should include StatisticsAnalyzerInterface"

    # Test that it implements the calculate_statistics method
    assert analyzer_class.method_defined?(:calculate_statistics),
      "DependencyStatisticsCalculator should implement calculate_statistics method"
  end

  def test_interface_segregation_principle
    # Test that interfaces are properly segregated (not too broad)
    
    # AnalyzerInterface should be minimal
    analyzer_interface = RailsDependencyExplorer::Analysis::Interfaces::AnalyzerInterface
    analyzer_methods = analyzer_interface.instance_methods(false)
    
    assert analyzer_methods.length <= 2,
      "AnalyzerInterface should be minimal (max 2 methods), has: #{analyzer_methods}"
    
    # GraphAnalyzerInterface should be focused on graph analysis
    graph_interface = RailsDependencyExplorer::Analysis::Interfaces::GraphAnalyzerInterface
    graph_methods = graph_interface.instance_methods(false)

    assert graph_methods.length <= 5,
      "GraphAnalyzerInterface should be focused (max 5 methods), has: #{graph_methods}"

    # StatisticsAnalyzerInterface should be focused on statistics
    stats_interface = RailsDependencyExplorer::Analysis::Interfaces::StatisticsAnalyzerInterface
    stats_methods = stats_interface.instance_methods(false)

    assert stats_methods.length <= 5,
      "StatisticsAnalyzerInterface should be focused (max 5 methods), has: #{stats_methods}"
  end

  def test_rails_component_analyzer_implements_interface
    analyzer_class = RailsDependencyExplorer::Analysis::Analyzers::RailsComponentAnalyzer

    # Test that RailsComponentAnalyzer includes AnalyzerInterface
    assert analyzer_class.ancestors.include?(RailsDependencyExplorer::Analysis::Interfaces::AnalyzerInterface),
      "RailsComponentAnalyzer should include AnalyzerInterface"

    # Test that it implements the analyze method
    assert analyzer_class.method_defined?(:analyze),
      "RailsComponentAnalyzer should implement analyze method"
  end

  def test_rails_configuration_analyzer_implements_interface
    analyzer_class = RailsDependencyExplorer::Analysis::Analyzers::RailsConfigurationAnalyzer

    # Test that RailsConfigurationAnalyzer includes AnalyzerInterface
    assert analyzer_class.ancestors.include?(RailsDependencyExplorer::Analysis::Interfaces::AnalyzerInterface),
      "RailsConfigurationAnalyzer should include AnalyzerInterface"

    # Test that it implements the analyze method
    assert analyzer_class.method_defined?(:analyze),
      "RailsConfigurationAnalyzer should implement analyze method"
  end

  def test_activerecord_relationship_analyzer_implements_interface
    analyzer_class = RailsDependencyExplorer::Analysis::Analyzers::ActiveRecordRelationshipAnalyzer

    # Test that ActiveRecordRelationshipAnalyzer includes AnalyzerInterface
    assert analyzer_class.ancestors.include?(RailsDependencyExplorer::Analysis::Interfaces::AnalyzerInterface),
      "ActiveRecordRelationshipAnalyzer should include AnalyzerInterface"

    # Test that it implements the analyze method
    assert analyzer_class.method_defined?(:analyze),
      "ActiveRecordRelationshipAnalyzer should implement analyze method"
  end

  def test_interface_method_signatures
    # Test that interface methods have proper signatures (accept dependency_data)

    # Create test instances to verify method signatures
    dependency_data = { "TestClass" => ["TestDependency"] }

    # Test AnalyzerInterface compliance through CircularDependencyAnalyzer
    analyzer = RailsDependencyExplorer::Analysis::Analyzers::CircularDependencyAnalyzer.new(dependency_data)

    # Should respond to analyze method
    assert_respond_to analyzer, :analyze,
      "Analyzer should respond to analyze method"

    # analyze method should accept optional dependency_data parameter for pipeline compatibility
    assert_equal(-1, analyzer.method(:analyze).arity,
      "analyze method should accept optional dependency_data parameter")
  end
end
