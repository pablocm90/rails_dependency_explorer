# frozen_string_literal: true

require "minitest/autorun"
require_relative "../test_helper"

class DotFormatAdapterArchitecturalTest < Minitest::Test
  def setup
    @adapter = RailsDependencyExplorer::Output::DotFormatAdapter.new
  end

  def test_dot_format_highlights_cross_namespace_cycles
    graph_data = {
      edges: [
        ["App::Models::User", "Services::UserService"],
        ["Services::UserService", "App::Models::User"]
      ]
    }
    cross_namespace_cycles = [
      {
        cycle: ["App::Models::User", "Services::UserService", "App::Models::User"],
        namespaces: ["App::Models", "Services"],
        severity: "high"
      }
    ]

    result = @adapter.format_with_architectural_analysis(
      graph_data,
      architectural_analysis: { cross_namespace_cycles: cross_namespace_cycles }
    )

    # Should have architectural cycle edges with special styling
    assert_includes result, 'color="red"'
    assert_includes result, 'style="bold"'
    assert_includes result, 'label="cross-namespace cycle"'
    assert_includes result, '"App::Models::User" -> "Services::UserService"'
    assert_includes result, '"Services::UserService" -> "App::Models::User"'
  end

  def test_dot_format_handles_no_cross_namespace_cycles
    graph_data = {
      edges: [
        ["User", "UserService"],
        ["UserService", "User"]
      ]
    }
    cross_namespace_cycles = []

    result = @adapter.format_with_architectural_analysis(
      graph_data,
      architectural_analysis: { cross_namespace_cycles: cross_namespace_cycles }
    )

    # Should not have architectural cycle styling when no cycles
    refute_includes result, 'color="red"'
    refute_includes result, 'label="cross-namespace cycle"'
    # But should still have normal edges
    assert_includes result, '"User" -> "UserService"'
    assert_includes result, '"UserService" -> "User"'
  end

  def test_dot_format_adds_architectural_legend
    graph_data = {
      edges: [["User", "UserService"]]
    }
    cross_namespace_cycles = [
      {
        cycle: ["App::Models::User", "Services::UserService", "App::Models::User"],
        namespaces: ["App::Models", "Services"],
        severity: "high"
      }
    ]

    result = @adapter.format_with_architectural_analysis(
      graph_data,
      architectural_analysis: { cross_namespace_cycles: cross_namespace_cycles }
    )

    # Should include legend for architectural concerns
    assert_includes result, 'subgraph cluster_legend'
    assert_includes result, 'label="Legend"'
    assert_includes result, 'Cross-Namespace Cycle'
  end
end
