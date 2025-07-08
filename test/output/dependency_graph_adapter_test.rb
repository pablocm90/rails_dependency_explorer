# frozen_string_literal: true

require "minitest/autorun"
require_relative "../test_helper"

class DependencyGraphAdapterTest < Minitest::Test
  def setup
    @adapter = RailsDependencyExplorer::Output::DependencyGraphAdapter.new
  end

  def test_dependency_graph_adapter_converts_single_dependency_to_basic_graph_structure
    dependency_data = {"Player" => [{"Enemy" => ["health"]}]}

    result = @adapter.to_graph(dependency_data)
    expected = {
      nodes: ["Player", "Enemy"],
      edges: [["Player", "Enemy"]]
    }

    assert_equal expected, result
  end

  def test_dependency_graph_adapter_handles_multiple_dependencies
    dependency_data = {
      "Player" => [{"Enemy" => ["health"]}, {"Logger" => ["info"]}],
      "Enemy" => [{"Logger" => ["debug"]}]
    }

    result = @adapter.to_graph(dependency_data)

    expected_nodes = ["Player", "Enemy", "Logger"]
    expected_edges = [["Player", "Enemy"], ["Player", "Logger"], ["Enemy", "Logger"]]

    assert_equal expected_nodes.sort, result[:nodes].sort
    assert_equal expected_edges.sort, result[:edges].sort
  end

  def test_dependency_graph_adapter_handles_empty_dependency_data
    dependency_data = {}

    result = @adapter.to_graph(dependency_data)
    expected = {
      nodes: [],
      edges: []
    }

    assert_equal expected, result
  end

  def test_dependency_graph_adapter_handles_class_with_no_dependencies
    dependency_data = {"Player" => []}

    result = @adapter.to_graph(dependency_data)
    expected = {
      nodes: ["Player"],
      edges: []
    }

    assert_equal expected, result
  end

  def test_dependency_graph_adapter_deduplicates_nodes_and_edges
    dependency_data = {
      "Player" => [{"Enemy" => ["health"]}, {"Enemy" => ["damage"]}]
    }

    result = @adapter.to_graph(dependency_data)
    expected = {
      nodes: ["Player", "Enemy"],
      edges: [["Player", "Enemy"]]
    }

    assert_equal expected, result
  end
end
