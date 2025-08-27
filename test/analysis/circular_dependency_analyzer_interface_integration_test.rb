# frozen_string_literal: true

require 'test_helper'

class CircularDependencyAnalyzerInterfaceIntegrationTest < Minitest::Test
  def setup
    @dependency_data = {
      "A" => [{"B" => ["method1"]}],
      "B" => [{"C" => ["method2"]}],
      "C" => [{"A" => ["method3"]}],  # Creates cycle A -> B -> C -> A
      "D" => [{"E" => ["method4"]}],
      "E" => []
    }
    @analyzer = RailsDependencyExplorer::Analysis::Analyzers::CircularDependencyAnalyzer.new(@dependency_data)
  end

  def test_circular_dependency_analyzer_includes_graph_analyzer_interface
    # Should include GraphAnalyzerInterface
    assert @analyzer.class.included_modules.include?(RailsDependencyExplorer::Analysis::Interfaces::GraphAnalyzerInterface)
  end

  def test_circular_dependency_analyzer_responds_to_graph_interface_methods
    # Should respond to GraphAnalyzerInterface methods
    assert_respond_to @analyzer, :build_adjacency_list
    assert_respond_to @analyzer, :analyze_graph_structure
  end

  def test_circular_dependency_analyzer_can_build_adjacency_list
    # Should be able to build adjacency list using interface method
    adjacency_list = @analyzer.build_adjacency_list
    
    assert_kind_of Hash, adjacency_list
    assert_equal ["B"], adjacency_list["A"]
    assert_equal ["C"], adjacency_list["B"]
    assert_equal ["A"], adjacency_list["C"]
    assert_equal ["E"], adjacency_list["D"]
    assert_equal [], adjacency_list["E"]
  end

  def test_circular_dependency_analyzer_can_analyze_graph_structure
    # Should be able to analyze graph structure using interface method
    structure = @analyzer.analyze_graph_structure
    
    assert_kind_of Hash, structure
    assert_includes structure.keys, :nodes
    assert_includes structure.keys, :edges
    assert_includes structure.keys, :components
    assert_includes structure.keys, :has_cycles
    assert_includes structure.keys, :strongly_connected_components
    
    # Should detect the cycle
    assert_equal true, structure[:has_cycles]
    assert_equal 5, structure[:nodes]
    assert_equal 4, structure[:edges]
  end

  def test_circular_dependency_analyzer_maintains_existing_functionality
    # Should still work with existing CycleDetectionInterface methods
    assert_respond_to @analyzer, :find_cycles

    # Should find the cycle
    cycles = @analyzer.find_cycles
    assert cycles.size > 0
  end

  def test_circular_dependency_analyzer_graph_interface_detects_same_cycles
    # Graph interface cycle detection should be consistent with existing cycle detection
    structure = @analyzer.analyze_graph_structure
    existing_cycles = @analyzer.find_cycles

    # Both should detect cycles consistently
    assert_equal (existing_cycles.size > 0), structure[:has_cycles]
  end

  def test_circular_dependency_analyzer_can_use_both_interfaces
    # Should be able to use both CycleDetectionInterface and GraphAnalyzerInterface
    
    # Use existing interface
    cycles_from_existing = @analyzer.find_cycles
    
    # Use graph interface
    structure = @analyzer.analyze_graph_structure
    
    # Both should detect cycles
    assert cycles_from_existing.size > 0
    assert_equal true, structure[:has_cycles]
  end

  def test_circular_dependency_analyzer_interface_methods_work_with_empty_data
    empty_analyzer = RailsDependencyExplorer::Analysis::Analyzers::CircularDependencyAnalyzer.new({})
    
    # Graph interface methods should handle empty data
    adjacency_list = empty_analyzer.build_adjacency_list
    assert_equal({}, adjacency_list)
    
    structure = empty_analyzer.analyze_graph_structure
    assert_equal 0, structure[:nodes]
    assert_equal 0, structure[:edges]
    assert_equal false, structure[:has_cycles]
  end
end
