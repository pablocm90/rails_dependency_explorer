# frozen_string_literal: true

require "minitest/autorun"
require "json"
require_relative "../test_helper"

class JsonFormatAdapterArchitecturalTest < Minitest::Test
  def setup
    @adapter = RailsDependencyExplorer::Output::JsonFormatAdapter.new
  end

  def test_json_format_includes_architectural_analysis_section
    dependency_data = {"User" => [{"UserService" => ["validate"]}]}
    cross_namespace_cycles = [
      {
        cycle: ["App::Models::User", "Services::UserService", "App::Models::User"],
        namespaces: ["App::Models", "Services"],
        severity: "high"
      }
    ]

    result = @adapter.format_with_architectural_analysis(
      dependency_data, 
      nil, 
      architectural_analysis: { cross_namespace_cycles: cross_namespace_cycles }
    )
    parsed = JSON.parse(result)

    assert parsed.key?("architectural_analysis")
    assert parsed["architectural_analysis"].key?("cross_namespace_cycles")
    
    cycles = parsed["architectural_analysis"]["cross_namespace_cycles"]
    assert_equal 1, cycles.length
    assert_equal ["App::Models::User", "Services::UserService", "App::Models::User"], cycles[0]["cycle"]
    assert_equal ["App::Models", "Services"], cycles[0]["namespaces"]
    assert_equal "high", cycles[0]["severity"]
  end

  def test_json_format_handles_empty_cross_namespace_cycles
    dependency_data = {"User" => [{"UserService" => ["validate"]}]}
    cross_namespace_cycles = []

    result = @adapter.format_with_architectural_analysis(
      dependency_data, 
      nil, 
      architectural_analysis: { cross_namespace_cycles: cross_namespace_cycles }
    )
    parsed = JSON.parse(result)

    assert parsed.key?("architectural_analysis")
    assert_equal [], parsed["architectural_analysis"]["cross_namespace_cycles"]
  end

  def test_json_format_maintains_existing_structure_with_architectural_analysis
    dependency_data = {"User" => [{"UserService" => ["validate"]}]}
    statistics = { total_classes: 2, total_dependencies: 1 }
    cross_namespace_cycles = [
      {
        cycle: ["App::Models::User", "Services::UserService", "App::Models::User"],
        namespaces: ["App::Models", "Services"],
        severity: "high"
      }
    ]

    result = @adapter.format_with_architectural_analysis(
      dependency_data, 
      statistics, 
      architectural_analysis: { cross_namespace_cycles: cross_namespace_cycles }
    )
    parsed = JSON.parse(result)

    # Verify existing structure is maintained
    assert parsed.key?("dependencies")
    assert parsed.key?("statistics")
    assert_equal 2, parsed["statistics"]["total_classes"]
    
    # Verify architectural analysis is added
    assert parsed.key?("architectural_analysis")
    assert_equal 1, parsed["architectural_analysis"]["cross_namespace_cycles"].length
  end
end
