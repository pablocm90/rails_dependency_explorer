# frozen_string_literal: true

require "test_helper"

# Tests for DepthCalculationState handling of circular dependencies.
# These tests verify that depth calculation doesn't cause stack overflow
# when circular dependencies exist in the dependency graph.
class DepthCalculationCircularDependencyTest < Minitest::Test
  def test_handles_simple_circular_dependency_without_stack_overflow
    # A depends on B, B depends on A (circular)
    reverse_graph = {
      "A" => ["B"],  # B depends on A
      "B" => ["A"]   # A depends on B
    }
    state = RailsDependencyExplorer::Analysis::DepthCalculationState.new(reverse_graph)

    # This should not cause stack overflow
    depth_a = state.calculate_node_depth("A")
    depth_b = state.calculate_node_depth("B")

    # In a circular dependency, both nodes should have the same depth
    # The exact value depends on the cycle handling strategy
    assert_kind_of Integer, depth_a
    assert_kind_of Integer, depth_b
    assert depth_a >= 0
    assert depth_b >= 0
  end

  def test_handles_three_node_circular_dependency
    # A -> B -> C -> A (circular)
    reverse_graph = {
      "A" => ["C"],  # C depends on A
      "B" => ["A"],  # A depends on B  
      "C" => ["B"]   # B depends on C
    }
    state = RailsDependencyExplorer::Analysis::DepthCalculationState.new(reverse_graph)

    # This should not cause stack overflow
    depth_a = state.calculate_node_depth("A")
    depth_b = state.calculate_node_depth("B")
    depth_c = state.calculate_node_depth("C")

    # All nodes in the cycle should have valid depths
    assert_kind_of Integer, depth_a
    assert_kind_of Integer, depth_b
    assert_kind_of Integer, depth_c
    assert depth_a >= 0
    assert depth_b >= 0
    assert depth_c >= 0
  end

  def test_handles_self_referencing_dependency
    # A depends on itself
    reverse_graph = {
      "A" => ["A"]  # A depends on A
    }
    state = RailsDependencyExplorer::Analysis::DepthCalculationState.new(reverse_graph)

    # This should not cause stack overflow
    depth_a = state.calculate_node_depth("A")

    assert_kind_of Integer, depth_a
    assert depth_a >= 0
  end

  def test_handles_mixed_circular_and_acyclic_dependencies
    # A -> B -> C -> A (circular)
    # D -> E (acyclic)
    # F -> A (connects to circular part)
    reverse_graph = {
      "A" => ["C", "F"],  # C and F depend on A
      "B" => ["A"],       # A depends on B
      "C" => ["B"],       # B depends on C
      "D" => [],          # Nothing depends on D
      "E" => ["D"],       # D depends on E
      "F" => []           # Nothing depends on F
    }
    state = RailsDependencyExplorer::Analysis::DepthCalculationState.new(reverse_graph)

    # Calculate depths for all nodes - should not cause stack overflow
    depth_a = state.calculate_node_depth("A")
    depth_b = state.calculate_node_depth("B")
    depth_c = state.calculate_node_depth("C")
    depth_d = state.calculate_node_depth("D")
    depth_e = state.calculate_node_depth("E")
    depth_f = state.calculate_node_depth("F")

    # All depths should be valid integers
    [depth_a, depth_b, depth_c, depth_d, depth_e, depth_f].each do |depth|
      assert_kind_of Integer, depth
      assert depth >= 0
    end

    # Acyclic part should have expected depths
    assert_equal 0, depth_d  # No dependents
    assert_equal 1, depth_e  # E -> D
    assert_equal 0, depth_f  # No dependents
  end

  def test_handles_complex_circular_dependency_with_multiple_cycles
    # Multiple interconnected cycles:
    # A -> B -> A (cycle 1)
    # C -> D -> C (cycle 2)  
    # B -> C (connects cycles)
    reverse_graph = {
      "A" => ["B"],       # B depends on A
      "B" => ["A", "C"],  # A and C depend on B
      "C" => ["D"],       # D depends on C
      "D" => ["C"]        # C depends on D
    }
    state = RailsDependencyExplorer::Analysis::DepthCalculationState.new(reverse_graph)

    # Calculate depths - should not cause stack overflow
    depth_a = state.calculate_node_depth("A")
    depth_b = state.calculate_node_depth("B")
    depth_c = state.calculate_node_depth("C")
    depth_d = state.calculate_node_depth("D")

    # All depths should be valid
    [depth_a, depth_b, depth_c, depth_d].each do |depth|
      assert_kind_of Integer, depth
      assert depth >= 0
    end
  end

  def test_integration_with_dependency_depth_analyzer_handles_cycles
    # Test the full integration with DependencyDepthAnalyzer
    # to ensure circular dependencies don't cause stack overflow
    # in the complete analysis workflow
    dependency_data = {
      "User" => [{"Post" => ["create"]}],
      "Post" => [{"Comment" => ["add"]}, {"User" => ["notify"]}],  # Creates cycle: User -> Post -> User
      "Comment" => [{"User" => ["mention"]}],  # Comment -> User (extends cycle)
      "Admin" => [{"User" => ["manage"]}]      # Admin -> User (acyclic branch)
    }

    analyzer = RailsDependencyExplorer::Analysis::DependencyDepthAnalyzer.new(dependency_data)

    # This should complete without stack overflow
    depths = analyzer.calculate_depth

    # Verify all classes have valid depths
    assert_kind_of Hash, depths
    assert depths.key?("User")
    assert depths.key?("Post")
    assert depths.key?("Comment")
    assert depths.key?("Admin")

    # All depths should be non-negative integers
    depths.each do |class_name, depth|
      assert_kind_of Integer, depth, "Depth for #{class_name} should be an integer"
      assert depth >= 0, "Depth for #{class_name} should be non-negative, got #{depth}"
    end

    # Admin should have a reasonable depth since it's not in a cycle
    assert depths["Admin"] >= 0
  end

  def test_memoization_works_correctly_with_cycle_detection
    # Verify that memoization still works correctly even with cycle detection
    reverse_graph = {
      "A" => ["B"],  # B depends on A
      "B" => ["A"],  # A depends on B (circular)
      "C" => []      # C has no dependents (acyclic)
    }
    state = RailsDependencyExplorer::Analysis::DepthCalculationState.new(reverse_graph)

    # Calculate depth multiple times - should use memoization
    depth_a1 = state.calculate_node_depth("A")
    depth_a2 = state.calculate_node_depth("A")
    depth_c1 = state.calculate_node_depth("C")
    depth_c2 = state.calculate_node_depth("C")

    # Results should be consistent (memoized)
    assert_equal depth_a1, depth_a2
    assert_equal depth_c1, depth_c2

    # Verify memoization cache contains the results
    assert_equal depth_a1, state.memo["A"]
    assert_equal depth_c1, state.memo["C"]

    # C should have depth 0 (no dependents)
    assert_equal 0, depth_c1
  end
end
