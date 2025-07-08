# frozen_string_literal: true

require "minitest/autorun"
require "json"
require_relative "../test_helper"

class DependencyVisualizerTest < Minitest::Test
  def setup
    @visualizer = RailsDependencyExplorer::Output::DependencyVisualizer.new
  end

  def test_dependency_visualizer_converts_single_dependency_to_basic_graph_structure
    dependency_data = {"Player" => [{"Enemy" => ["health"]}]}

    result = @visualizer.to_graph(dependency_data)
    expected = {
      nodes: ["Player", "Enemy"],
      edges: [["Player", "Enemy"]]
    }

    assert_equal expected, result
  end

  def test_dependency_visualizer_generates_dot_format_for_visual_output
    dependency_data = {"Player" => [{"Enemy" => ["health"]}]}

    result = @visualizer.to_dot(dependency_data)
    expected = "digraph dependencies {\n  \"Player\" -> \"Enemy\";\n}"

    assert_equal expected, result
  end

  def test_dependency_visualizer_generates_json_format_with_statistics
    dependency_data = {"Player" => [{"Enemy" => ["health"]}, {"Logger" => ["info"]}]}
    statistics = {
      total_classes: 1,
      total_dependencies: 2,
      most_used_dependency: "Enemy",
      dependency_counts: {"Enemy" => 1, "Logger" => 1}
    }

    result = @visualizer.to_json(dependency_data, statistics)
    parsed = JSON.parse(result)

    expected_dependencies = {"Player" => ["Enemy", "Logger"]}
    expected_statistics = {
      "total_classes" => 1,
      "total_dependencies" => 2,
      "most_used_dependency" => "Enemy",
      "dependency_counts" => {"Enemy" => 1, "Logger" => 1}
    }

    assert_equal expected_dependencies, parsed['dependencies']
    assert_equal expected_statistics, parsed['statistics']
  end

  def test_dependency_visualizer_generates_json_format_without_statistics
    dependency_data = {"Player" => [{"Enemy" => ["health"]}]}

    result = @visualizer.to_json(dependency_data)
    parsed = JSON.parse(result)

    expected_dependencies = {"Player" => ["Enemy"]}
    assert_equal expected_dependencies, parsed['dependencies']
    assert_nil parsed['statistics']
  end
end
