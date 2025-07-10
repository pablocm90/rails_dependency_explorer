# frozen_string_literal: true

require "minitest/autorun"
require_relative "../test_helper"

# Tests for AnalysisResult class functionality including delegation,
# visualization coordination, and integration with various analysis components.
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





  def test_analysis_result_handles_class_with_no_dependencies
    dependency_data = {"Standalone" => []}
    result = RailsDependencyExplorer::Analysis::AnalysisResult.new(dependency_data)

    graph = result.to_graph
    expected_graph = {
      nodes: ["Standalone"],
      edges: []
    }
    assert_equal expected_graph, graph
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
