# frozen_string_literal: true

require "minitest/autorun"
require_relative "../test_helper"
require_relative "../../lib/rails_dependency_explorer/analysis/depth_calculation_state"

class DepthCalculationStateTest < Minitest::Test
  def test_calculates_depth_for_node_with_no_dependents
    reverse_graph = { "A" => [] }
    state = RailsDependencyExplorer::Analysis::DepthCalculationState.new(reverse_graph)

    depth = state.calculate_node_depth("A")

    assert_equal 0, depth
  end

  def test_calculates_depth_for_node_with_single_dependent
    reverse_graph = { "A" => ["B"], "B" => [] }
    state = RailsDependencyExplorer::Analysis::DepthCalculationState.new(reverse_graph)

    depth = state.calculate_node_depth("A")

    assert_equal 1, depth
  end

  def test_calculates_depth_for_node_with_multiple_dependents
    reverse_graph = { "A" => ["B", "C"], "B" => [], "C" => [] }
    state = RailsDependencyExplorer::Analysis::DepthCalculationState.new(reverse_graph)

    depth = state.calculate_node_depth("A")

    assert_equal 1, depth
  end

  def test_calculates_depth_for_nested_dependencies
    reverse_graph = { "A" => ["B"], "B" => ["C"], "C" => [] }
    state = RailsDependencyExplorer::Analysis::DepthCalculationState.new(reverse_graph)

    depth = state.calculate_node_depth("A")

    assert_equal 2, depth
  end

  def test_handles_missing_node_in_reverse_graph
    reverse_graph = { "A" => [] }
    state = RailsDependencyExplorer::Analysis::DepthCalculationState.new(reverse_graph)

    depth = state.calculate_node_depth("B")

    assert_equal 0, depth
  end

  def test_memoizes_calculated_depths
    reverse_graph = { "A" => ["B"], "B" => [] }
    state = RailsDependencyExplorer::Analysis::DepthCalculationState.new(reverse_graph)

    # Calculate depth twice
    depth1 = state.calculate_node_depth("A")
    depth2 = state.calculate_node_depth("A")

    assert_equal depth1, depth2
    assert_equal 1, state.memo["A"]
  end

  def test_calculates_complex_dependency_tree
    reverse_graph = {
      "A" => ["B", "C"],
      "B" => ["D"],
      "C" => ["D", "E"],
      "D" => [],
      "E" => []
    }
    state = RailsDependencyExplorer::Analysis::DepthCalculationState.new(reverse_graph)

    depth_a = state.calculate_node_depth("A")
    depth_b = state.calculate_node_depth("B")
    depth_c = state.calculate_node_depth("C")

    assert_equal 2, depth_a  # A -> C -> E (or A -> C -> D)
    assert_equal 1, depth_b  # B -> D
    assert_equal 1, depth_c  # C -> D (or C -> E)
  end
end
