# frozen_string_literal: true

require 'test_helper'

class DependencyDepthAnalyzerInterfaceIntegrationTest < Minitest::Test
  def setup
    @dependency_data = {
      "A" => [{"B" => ["method1"]}],
      "B" => [{"C" => ["method2"]}],
      "C" => [{"D" => ["method3"]}],
      "D" => [],
      "E" => [{"F" => ["method4"]}],
      "F" => []
    }
    @analyzer = RailsDependencyExplorer::Analysis::DependencyDepthAnalyzer.new(@dependency_data)
  end

  def test_dependency_depth_analyzer_includes_graph_analyzer_interface
    # Should include GraphAnalyzerInterface
    assert @analyzer.class.included_modules.include?(RailsDependencyExplorer::Analysis::GraphAnalyzerInterface)
  end

  def test_dependency_depth_analyzer_responds_to_graph_interface_methods
    # Should respond to GraphAnalyzerInterface methods
    assert_respond_to @analyzer, :build_adjacency_list
    assert_respond_to @analyzer, :analyze_graph_structure
  end

  def test_dependency_depth_analyzer_can_build_adjacency_list
    # Should be able to build adjacency list using interface method
    adjacency_list = @analyzer.build_adjacency_list
    
    assert_kind_of Hash, adjacency_list
    assert_equal ["B"], adjacency_list["A"]
    assert_equal ["C"], adjacency_list["B"]
    assert_equal ["D"], adjacency_list["C"]
    assert_equal [], adjacency_list["D"]
    assert_equal ["F"], adjacency_list["E"]
    assert_equal [], adjacency_list["F"]
  end

  def test_dependency_depth_analyzer_can_analyze_graph_structure
    # Should be able to analyze graph structure using interface method
    structure = @analyzer.analyze_graph_structure
    
    assert_kind_of Hash, structure
    assert_includes structure.keys, :nodes
    assert_includes structure.keys, :edges
    assert_includes structure.keys, :components
    assert_includes structure.keys, :has_cycles
    assert_includes structure.keys, :strongly_connected_components
    
    # Should analyze the linear dependency chain structure
    assert_equal false, structure[:has_cycles]  # No cycles in this data
    assert_equal 6, structure[:nodes]  # A, B, C, D, E, F
    assert_equal 4, structure[:edges]  # A->B, B->C, C->D, E->F
    assert_equal 2, structure[:components]  # Two separate chains: A->B->C->D and E->F
  end

  def test_dependency_depth_analyzer_maintains_existing_functionality
    # Should still work with existing depth calculation methods
    assert_respond_to @analyzer, :calculate_depth

    # Should calculate depths correctly
    depths = @analyzer.calculate_depth
    assert_kind_of Hash, depths
    
    # Verify depth calculations for the chain A->B->C->D
    # Note: DependencyDepthAnalyzer calculates depth from leaves up
    assert_equal 0, depths["A"]  # A has depth 0 (root of chain)
    assert_equal 1, depths["B"]  # B has depth 1 (one level from root)
    assert_equal 2, depths["C"]  # C has depth 2 (two levels from root)
    assert_equal 3, depths["D"]  # D has depth 3 (three levels from root)
    assert_equal 0, depths["E"]  # E has depth 0 (root of chain)
    assert_equal 1, depths["F"]  # F has depth 1 (one level from root)
  end

  def test_dependency_depth_analyzer_graph_interface_complements_depth_analysis
    # Graph interface should provide additional insights beyond depth calculation
    structure = @analyzer.analyze_graph_structure
    depths = @analyzer.calculate_depth
    
    # Graph structure should be consistent with depth analysis
    # Nodes with highest depth should be leaf nodes (no outgoing edges)
    max_depth = depths.values.max
    leaf_nodes = depths.select { |_, depth| depth == max_depth }.keys
    adjacency_list = @analyzer.build_adjacency_list

    leaf_nodes.each do |node|
      assert_equal [], adjacency_list[node], "Node #{node} should have no outgoing edges"
    end
    
    # Graph components should match separate dependency chains
    assert_equal 2, structure[:components]  # Two separate chains
  end

  def test_dependency_depth_analyzer_can_use_both_interfaces
    # Should be able to use both depth calculation and graph analysis
    
    # Use existing depth interface
    depths = @analyzer.calculate_depth
    
    # Use graph interface
    structure = @analyzer.analyze_graph_structure
    
    # Both should provide consistent information
    assert depths.size > 0
    assert_equal depths.keys.size, structure[:nodes]
  end

  def test_dependency_depth_analyzer_interface_methods_work_with_empty_data
    empty_analyzer = RailsDependencyExplorer::Analysis::DependencyDepthAnalyzer.new({})
    
    # Graph interface methods should handle empty data
    adjacency_list = empty_analyzer.build_adjacency_list
    assert_equal({}, adjacency_list)
    
    structure = empty_analyzer.analyze_graph_structure
    assert_equal 0, structure[:nodes]
    assert_equal 0, structure[:edges]
    assert_equal false, structure[:has_cycles]
    assert_equal 0, structure[:components]
  end

  def test_dependency_depth_analyzer_interface_methods_work_with_cyclic_data
    # Test with cyclic data to verify graph interface handles cycles
    cyclic_data = {
      "A" => [{"B" => ["method1"]}],
      "B" => [{"C" => ["method2"]}],
      "C" => [{"A" => ["method3"]}]  # Creates cycle A -> B -> C -> A
    }
    
    cyclic_analyzer = RailsDependencyExplorer::Analysis::DependencyDepthAnalyzer.new(cyclic_data)
    
    # Graph interface should detect cycles
    structure = cyclic_analyzer.analyze_graph_structure
    assert_equal true, structure[:has_cycles]
    assert_equal 3, structure[:nodes]
    assert_equal 3, structure[:edges]
    assert_equal 1, structure[:components]  # All nodes in one strongly connected component
    
    # Depth calculation should still work (may handle cycles differently)
    depths = cyclic_analyzer.calculate_depth
    assert_kind_of Hash, depths
  end

  def test_dependency_depth_analyzer_graph_structure_provides_additional_insights
    # Graph structure analysis should provide insights beyond simple depth calculation
    structure = @analyzer.analyze_graph_structure
    
    # Should identify strongly connected components
    assert_includes structure.keys, :strongly_connected_components
    assert_kind_of Array, structure[:strongly_connected_components]
    
    # For acyclic graph, each node should be its own SCC
    sccs = structure[:strongly_connected_components]
    assert_equal 6, sccs.size  # 6 nodes = 6 SCCs in acyclic graph
    
    # Each SCC should contain exactly one node
    sccs.each do |scc|
      assert_equal 1, scc.size
    end
  end
end
