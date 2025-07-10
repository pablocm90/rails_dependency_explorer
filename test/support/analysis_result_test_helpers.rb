# frozen_string_literal: true

module AnalysisResultTestHelpers
  # Creates AnalysisResult instances with common test data
  def create_simple_analysis_result
    dependency_data = {"Player" => [{"Enemy" => ["health"]}]}
    RailsDependencyExplorer::Analysis::AnalysisResult.new(dependency_data)
  end

  def create_complex_analysis_result
    dependency_data = {
      "Player" => [
        {"Enemy" => ["take_damage", "health"]},
        {"GameState" => ["current"]},
        {"Logger" => ["info"]}
      ]
    }
    RailsDependencyExplorer::Analysis::AnalysisResult.new(dependency_data)
  end

  def create_rails_analysis_result
    dependency_data = {
      "User" => [
        {"ApplicationRecord" => [[]]},
        {"ActiveRecord::belongs_to" => ["Account"]},
        {"ActiveRecord::has_many" => ["Post"]}
      ]
    }
    RailsDependencyExplorer::Analysis::AnalysisResult.new(dependency_data)
  end

  # Common assertions for analysis results
  def assert_simple_graph_structure(result)
    expected = {
      nodes: ["Player", "Enemy"],
      edges: [["Player", "Enemy"]]
    }
    assert_equal expected, result.to_graph
  end

  def assert_complex_graph_structure(result)
    expected = {
      nodes: ["Player", "Enemy", "GameState", "Logger"],
      edges: [["Player", "Enemy"], ["Player", "GameState"], ["Player", "Logger"]]
    }
    assert_equal expected, result.to_graph
  end

  def assert_rails_graph_structure(result)
    expected_nodes = ["User", "ApplicationRecord", "Account", "Post"]
    expected_edges = [["User", "ApplicationRecord"], ["User", "Account"], ["User", "Post"]]
    
    rails_graph = result.to_rails_graph
    assert_equal expected_nodes.sort, rails_graph[:nodes].sort
    assert_equal expected_edges.sort, rails_graph[:edges].sort
  end

  # Common output format assertions
  def assert_dot_format_output(result, expected_edges)
    dot_output = result.to_dot
    assert_includes dot_output, "digraph dependencies"
    expected_edges.each do |source, target|
      assert_includes dot_output, "\"#{source}\" -> \"#{target}\""
    end
  end

  def assert_json_format_output(result)
    json_output = result.to_json
    parsed_json = JSON.parse(json_output)
    
    assert parsed_json.key?("nodes")
    assert parsed_json.key?("edges")
    assert parsed_json["nodes"].is_a?(Array)
    assert parsed_json["edges"].is_a?(Array)
  end

  def assert_csv_format_output(result)
    csv_output = result.to_csv
    lines = csv_output.split("\n")
    
    assert_equal "Source,Target,Methods", lines.first
    assert lines.length > 1, "CSV should have data rows"
  end

  def assert_console_format_output(result)
    console_output = result.to_console
    assert_includes console_output, "Dependencies:"
    assert console_output.length > 0
  end
end
