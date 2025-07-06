# frozen_string_literal: true

require "minitest/autorun"
require_relative "../test_helper"

class AnalysisResultTest < Minitest::Test
  def test_analysis_result_converts_single_dependency_to_graph
    dependency_data = {"Player" => [{"Enemy" => ["health"]}]}
    result = RailsDependencyExplorer::Analysis::AnalysisResult.new(dependency_data)

    expected = {
      nodes: ["Player", "Enemy"],
      edges: [["Player", "Enemy"]]
    }

    assert_equal expected, result.to_graph
  end

  def test_analysis_result_converts_multiple_dependencies_to_graph
    dependency_data = {
      "Player" => [
        {"Enemy" => ["take_damage", "health"]},
        {"GameState" => ["current"]},
        {"Logger" => ["info"]}
      ]
    }
    result = RailsDependencyExplorer::Analysis::AnalysisResult.new(dependency_data)

    expected = {
      nodes: ["Player", "Enemy", "GameState", "Logger"],
      edges: [["Player", "Enemy"], ["Player", "GameState"], ["Player", "Logger"]]
    }

    assert_equal expected, result.to_graph
  end

  def test_analysis_result_handles_empty_dependency_data
    dependency_data = {}
    result = RailsDependencyExplorer::Analysis::AnalysisResult.new(dependency_data)

    expected = {
      nodes: [],
      edges: []
    }

    assert_equal expected, result.to_graph
  end

  def test_analysis_result_converts_to_dot_format
    dependency_data = {"Player" => [{"Enemy" => ["health"]}]}
    result = RailsDependencyExplorer::Analysis::AnalysisResult.new(dependency_data)
    dot_output = result.to_dot

    assert_instance_of String, dot_output
    assert_includes dot_output, "digraph"
    assert_includes dot_output, "Player"
    assert_includes dot_output, "Enemy"
    assert_includes dot_output, "\"Player\" -> \"Enemy\""
  end

  def test_analysis_result_provides_statistics_for_simple_case
    dependency_data = {"Player" => [{"Enemy" => ["health"]}]}
    result = RailsDependencyExplorer::Analysis::AnalysisResult.new(dependency_data)
    stats = result.statistics

    expected_stats = {
      total_classes: 1,
      total_dependencies: 1,
      most_used_dependency: "Enemy",
      dependency_counts: {"Enemy" => 1}
    }

    assert_equal expected_stats, stats
  end

  def test_analysis_result_provides_statistics_for_complex_case
    dependency_data = {
      "Player" => [
        {"Enemy" => ["health"]},
        {"Logger" => ["info"]}
      ],
      "Game" => [
        {"Player" => ["new"]},
        {"Logger" => ["debug"]},
        {"Enemy" => ["cleanup"]}
      ],
      "Enemy" => [
        {"Logger" => ["warn"]}
      ]
    }
    result = RailsDependencyExplorer::Analysis::AnalysisResult.new(dependency_data)
    stats = result.statistics

    expected_stats = {
      total_classes: 3,
      total_dependencies: 3,
      most_used_dependency: "Logger",
      dependency_counts: {
        "Enemy" => 2,
        "Logger" => 3,
        "Player" => 1
      }
    }

    assert_equal expected_stats, stats
  end

  def test_analysis_result_handles_empty_statistics
    dependency_data = {}
    result = RailsDependencyExplorer::Analysis::AnalysisResult.new(dependency_data)
    stats = result.statistics

    expected_stats = {
      total_classes: 0,
      total_dependencies: 0,
      most_used_dependency: nil,
      dependency_counts: {}
    }

    assert_equal expected_stats, stats
  end

  def test_analysis_result_handles_class_with_no_dependencies
    dependency_data = {"Standalone" => []}
    result = RailsDependencyExplorer::Analysis::AnalysisResult.new(dependency_data)

    graph = result.to_graph
    expected_graph = {
      nodes: ["Standalone"],
      edges: []
    }
    assert_equal expected_graph, graph

    stats = result.statistics
    expected_stats = {
      total_classes: 1,
      total_dependencies: 0,
      most_used_dependency: nil,
      dependency_counts: {}
    }
    assert_equal expected_stats, stats
  end

  def test_analysis_result_detects_circular_dependencies
    dependency_data = {
      "Player" => [{"Enemy" => ["take_damage"]}],
      "Enemy" => [{"Player" => ["take_damage"]}],
      "Game" => [{"Player" => ["new"]}]
    }
    result = RailsDependencyExplorer::Analysis::AnalysisResult.new(dependency_data)
    cycles = result.circular_dependencies

    expected_cycles = [["Player", "Enemy", "Player"]]
    assert_equal expected_cycles, cycles
  end

  def test_analysis_result_handles_no_circular_dependencies
    dependency_data = {
      "Player" => [{"Enemy" => ["take_damage"]}],
      "Game" => [{"Player" => ["new"]}]
    }
    result = RailsDependencyExplorer::Analysis::AnalysisResult.new(dependency_data)
    cycles = result.circular_dependencies

    assert_equal [], cycles
  end
end
