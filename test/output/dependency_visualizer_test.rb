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

  def test_dependency_visualizer_generates_csv_format_for_spreadsheet_analysis
    dependency_data = {"Player" => [{"Enemy" => ["health"]}]}

    result = @visualizer.to_csv(dependency_data)
    lines = result.split("\n")

    assert_equal "Source,Target,Methods", lines.first
    assert_equal "Player,Enemy,health", lines.last
  end

  def test_dependency_visualizer_provides_rails_aware_graph
    dependency_data = {
      "User" => [
        {"ApplicationRecord" => [[]]},
        {"ActiveRecord::belongs_to" => ["Account"]},
        {"ActiveRecord::has_many" => ["Post"]}
      ]
    }

    result = @visualizer.to_rails_graph(dependency_data)

    expected_nodes = ["User", "ApplicationRecord", "Account", "Post"]
    expected_edges = [["User", "ApplicationRecord"], ["User", "Account"], ["User", "Post"]]

    assert_equal expected_nodes.sort, result[:nodes].sort
    assert_equal expected_edges.sort, result[:edges].sort
  end

  def test_dependency_visualizer_provides_rails_aware_dot_format
    dependency_data = {
      "User" => [{"ActiveRecord::belongs_to" => ["Account"]}]
    }

    result = @visualizer.to_rails_dot(dependency_data)
    expected = "digraph dependencies {\n  \"User\" -> \"Account\";\n}"

    assert_equal expected, result
  end
end
