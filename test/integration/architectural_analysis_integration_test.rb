# frozen_string_literal: true

require "minitest/autorun"
require "json"
require_relative "../test_helper"

class ArchitecturalAnalysisIntegrationTest < Minitest::Test
  def setup
    @dependency_data = {
      "App::Models::User" => [{"Services::UserService" => ["validate"]}],
      "Services::UserService" => [{"App::Models::User" => ["find"]}],
      "Controllers::UsersController" => [{"App::Models::User" => ["create"]}]
    }
  end

  def test_end_to_end_architectural_analysis_through_analysis_result
    result = RailsDependencyExplorer::Analysis::AnalysisResult.new(@dependency_data)
    
    # Verify cross-namespace cycles are detected
    cross_namespace_cycles = result.cross_namespace_cycles
    assert_equal 1, cross_namespace_cycles.length
    assert_equal ["App::Models::User", "Services::UserService", "App::Models::User"], cross_namespace_cycles[0][:cycle]
    assert_equal ["App::Models", "Services"], cross_namespace_cycles[0][:namespaces]
    assert_equal "high", cross_namespace_cycles[0][:severity]
  end

  def test_architectural_analysis_appears_in_json_output
    result = RailsDependencyExplorer::Analysis::AnalysisResult.new(@dependency_data)
    json_output = result.to_json
    parsed = JSON.parse(json_output)

    # Should include architectural analysis section
    assert parsed.key?("architectural_analysis")
    assert parsed["architectural_analysis"].key?("cross_namespace_cycles")
    
    cycles = parsed["architectural_analysis"]["cross_namespace_cycles"]
    assert_equal 1, cycles.length
    assert_equal ["App::Models::User", "Services::UserService", "App::Models::User"], cycles[0]["cycle"]
    assert_equal "high", cycles[0]["severity"]
  end

  def test_architectural_analysis_appears_in_html_output
    result = RailsDependencyExplorer::Analysis::AnalysisResult.new(@dependency_data)
    html_output = result.to_html

    # Should include architectural analysis section
    assert_includes html_output, "<h2>Architectural Analysis</h2>"
    assert_includes html_output, "<h3>Cross-Namespace Cycles</h3>"
    assert_includes html_output, "class='severity-high'"
    assert_includes html_output, "App::Models::User → Services::UserService → App::Models::User"
  end

  def test_architectural_analysis_appears_in_console_output
    result = RailsDependencyExplorer::Analysis::AnalysisResult.new(@dependency_data)
    console_output = result.to_console

    # Should include architectural analysis section
    assert_includes console_output, "Cross-Namespace Cycles:"
    assert_includes console_output, "⚠️  HIGH SEVERITY"
    assert_includes console_output, "App::Models::User -> Services::UserService -> App::Models::User"
    assert_includes console_output, "Namespaces: App::Models, Services"
  end

  def test_architectural_analysis_appears_in_dot_output
    result = RailsDependencyExplorer::Analysis::AnalysisResult.new(@dependency_data)
    dot_output = result.to_dot

    # Should include architectural styling for cross-namespace cycles
    assert_includes dot_output, 'color="red"'
    assert_includes dot_output, 'style="bold"'
    assert_includes dot_output, 'label="cross-namespace cycle"'
    assert_includes dot_output, 'subgraph cluster_legend'
  end

  def test_architectural_analysis_appears_in_csv_output
    result = RailsDependencyExplorer::Analysis::AnalysisResult.new(@dependency_data)
    csv_output = result.to_csv

    # Should include architectural analysis columns
    assert_includes csv_output, "Cross_Namespace_Cycle"
    assert_includes csv_output, "Cycle_Severity"
    assert_includes csv_output, "Affected_Namespaces"
    
    # Should mark cross-namespace cycle dependencies
    lines = csv_output.split("\n")
    cycle_line = lines.find { |line| line.include?("App::Models::User,Services::UserService") }
    assert_includes cycle_line, "Yes"
    assert_includes cycle_line, "high"
    assert_includes cycle_line, "App::Models, Services"
  end

  def test_no_architectural_analysis_when_no_cycles
    clean_dependency_data = {
      "User" => [{"UserService" => ["validate"]}],
      "UserService" => [{"Database" => ["query"]}]
    }
    
    result = RailsDependencyExplorer::Analysis::AnalysisResult.new(clean_dependency_data)
    
    # Should have no cross-namespace cycles
    cross_namespace_cycles = result.cross_namespace_cycles
    assert_empty cross_namespace_cycles
    
    # JSON should not have architectural analysis section or should be empty
    json_output = result.to_json
    parsed = JSON.parse(json_output)
    
    # Should either not have the key or have empty array
    if parsed.key?("architectural_analysis")
      assert_empty parsed["architectural_analysis"]["cross_namespace_cycles"]
    end
  end
end
