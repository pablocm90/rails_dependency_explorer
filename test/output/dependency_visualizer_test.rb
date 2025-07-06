# frozen_string_literal: true

require "minitest/autorun"
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
end
