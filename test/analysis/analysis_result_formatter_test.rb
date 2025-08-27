# frozen_string_literal: true

require "minitest/autorun"
require_relative "../test_helper"

# Tests for AnalysisResultFormatter class focusing solely on output formatting.
# Verifies that the formatter handles various output formats correctly
# without being concerned with analysis coordination responsibilities.
class AnalysisResultFormatterTest < Minitest::Test
  def test_formatter_converts_single_dependency_to_graph
    formatter = create_simple_formatter
    assert_simple_graph_structure_for_formatter(formatter)
  end

  def test_formatter_converts_multiple_dependencies_to_graph
    formatter = create_complex_formatter
    expected = {
      nodes: ["Player", "Enemy", "GameState", "Logger"],
      edges: [["Player", "Enemy"], ["Player", "GameState"], ["Player", "Logger"]]
    }
    assert_equal expected, formatter.to_graph
  end

  def test_formatter_generates_dot_format
    formatter = create_simple_formatter
    dot_output = formatter.to_dot
    assert_includes dot_output, "digraph dependencies"
    assert_includes dot_output, "\"Player\" -> \"Enemy\""
  end

  def test_formatter_generates_json_format
    formatter = create_simple_formatter
    json_output = formatter.to_json
    parsed_json = JSON.parse(json_output)

    assert parsed_json.key?("dependencies")
    assert parsed_json["dependencies"].key?("Player")
  end

  def test_formatter_generates_html_format
    formatter = create_simple_formatter
    html_output = formatter.to_html
    assert_includes html_output, "<html>"
    assert_includes html_output, "Player"
  end

  def test_formatter_generates_console_format
    formatter = create_simple_formatter
    console_output = formatter.to_console
    assert_includes console_output, "Dependencies:"
    assert console_output.length > 0
  end

  def test_formatter_generates_csv_format
    formatter = create_simple_formatter
    csv_output = formatter.to_csv
    lines = csv_output.split("\n")

    assert_equal "Source,Target,Methods", lines.first
    assert lines.length > 1, "CSV should have data rows"
  end

  def test_formatter_generates_rails_graph
    formatter = create_rails_formatter
    rails_graph = formatter.to_rails_graph

    expected_nodes = ["User", "ApplicationRecord", "Account", "Post"]
    expected_edges = [["User", "ApplicationRecord"], ["User", "Account"], ["User", "Post"]]

    assert_equal expected_nodes.sort, rails_graph[:nodes].sort
    assert_equal expected_edges.sort, rails_graph[:edges].sort
  end

  def test_formatter_generates_rails_dot_format
    formatter = create_rails_formatter
    rails_dot = formatter.to_rails_dot

    assert_includes rails_dot, "digraph dependencies"
    assert_includes rails_dot, "\"User\" -> \"Account\""
    assert_includes rails_dot, "\"User\" -> \"Post\""
  end

  def test_formatter_handles_empty_dependency_data
    formatter = RailsDependencyExplorer::Analysis::Pipeline::AnalysisResultFormatter.new({})

    expected = {
      nodes: [],
      edges: []
    }

    assert_equal expected, formatter.to_graph
  end

  def test_formatter_works_with_statistics_provider
    # Create a mock statistics provider
    stats_provider = Object.new
    def stats_provider.statistics
      {total_classes: 1, total_dependencies: 1}
    end

    formatter = RailsDependencyExplorer::Analysis::Pipeline::AnalysisResultFormatter.new(
      simple_dependency_data,
      stats_provider
    )

    json_output = formatter.to_json
    parsed_json = JSON.parse(json_output)

    assert parsed_json.key?("statistics")
    assert_equal 1, parsed_json["statistics"]["total_classes"]
  end

  def test_formatter_works_without_statistics_provider
    formatter = RailsDependencyExplorer::Analysis::Pipeline::AnalysisResultFormatter.new(simple_dependency_data)

    json_output = formatter.to_json
    parsed_json = JSON.parse(json_output)

    # Should still work, just with nil statistics
    assert parsed_json.key?("statistics")
    assert_nil parsed_json["statistics"]
  end

  private

  def create_simple_formatter
    RailsDependencyExplorer::Analysis::Pipeline::AnalysisResultFormatter.new(simple_dependency_data)
  end

  def create_complex_formatter
    RailsDependencyExplorer::Analysis::Pipeline::AnalysisResultFormatter.new(complex_dependency_data)
  end

  def create_rails_formatter
    RailsDependencyExplorer::Analysis::Pipeline::AnalysisResultFormatter.new(rails_dependency_data)
  end

  def assert_simple_graph_structure_for_formatter(formatter)
    expected = {
      nodes: ["Player", "Enemy"],
      edges: [["Player", "Enemy"]]
    }
    assert_equal expected, formatter.to_graph
  end
end
