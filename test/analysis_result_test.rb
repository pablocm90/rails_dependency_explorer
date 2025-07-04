# frozen_string_literal: true

require "minitest/autorun"
require_relative "../lib/rails_dependency_explorer/analysis_result"

class AnalysisResultTest < Minitest::Test
  def test_analysis_result_converts_single_dependency_to_graph
    dependency_data = {"Player" => [{"Enemy" => ["health"]}]}
    result = RailsDependencyExplorer::AnalysisResult.new(dependency_data)
    
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
    result = RailsDependencyExplorer::AnalysisResult.new(dependency_data)
    
    expected = {
      nodes: ["Player", "Enemy", "GameState", "Logger"],
      edges: [["Player", "Enemy"], ["Player", "GameState"], ["Player", "Logger"]]
    }
    
    assert_equal expected, result.to_graph
  end

  def test_analysis_result_handles_empty_dependency_data
    dependency_data = {}
    result = RailsDependencyExplorer::AnalysisResult.new(dependency_data)
    
    expected = {
      nodes: [],
      edges: []
    }
    
    assert_equal expected, result.to_graph
  end
end
