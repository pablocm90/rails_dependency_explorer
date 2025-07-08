# frozen_string_literal: true

require "minitest/autorun"
require_relative "../test_helper"

class DotFormatAdapterTest < Minitest::Test
  def setup
    @adapter = RailsDependencyExplorer::Output::DotFormatAdapter.new
  end

  def test_dot_format_adapter_formats_single_edge_graph
    graph_data = {
      nodes: ["Player", "Enemy"],
      edges: [["Player", "Enemy"]]
    }

    result = @adapter.format(graph_data)
    expected = "digraph dependencies {\n  \"Player\" -> \"Enemy\";\n}"

    assert_equal expected, result
  end

  def test_dot_format_adapter_formats_multiple_edges_graph
    graph_data = {
      nodes: ["Player", "Enemy", "Logger"],
      edges: [["Player", "Enemy"], ["Player", "Logger"], ["Enemy", "Logger"]]
    }

    result = @adapter.format(graph_data)
    expected = "digraph dependencies {\n  \"Player\" -> \"Enemy\";\n  \"Player\" -> \"Logger\";\n  \"Enemy\" -> \"Logger\";\n}"

    assert_equal expected, result
  end

  def test_dot_format_adapter_handles_empty_graph
    graph_data = {
      nodes: [],
      edges: []
    }

    result = @adapter.format(graph_data)
    expected = "digraph dependencies {\n\n}"

    assert_equal expected, result
  end

  def test_dot_format_adapter_handles_nodes_without_edges
    graph_data = {
      nodes: ["Player"],
      edges: []
    }

    result = @adapter.format(graph_data)
    expected = "digraph dependencies {\n\n}"

    assert_equal expected, result
  end

  def test_dot_format_adapter_escapes_quotes_in_node_names
    graph_data = {
      nodes: ["Player\"Test", "Enemy"],
      edges: [["Player\"Test", "Enemy"]]
    }

    result = @adapter.format(graph_data)
    expected = "digraph dependencies {\n  \"Player\"Test\" -> \"Enemy\";\n}"

    assert_equal expected, result
  end
end
