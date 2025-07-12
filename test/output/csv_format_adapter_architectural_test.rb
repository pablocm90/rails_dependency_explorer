# frozen_string_literal: true

require "minitest/autorun"
require "csv"
require_relative "../test_helper"

class CsvFormatAdapterArchitecturalTest < Minitest::Test
  def setup
    @adapter = RailsDependencyExplorer::Output::CsvFormatAdapter.new
  end

  def test_csv_format_includes_architectural_analysis_columns
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

    lines = result.split("\n")
    headers = CSV.parse(lines[0])[0]
    
    # Should include architectural analysis columns
    assert_includes headers, "Cross_Namespace_Cycle"
    assert_includes headers, "Cycle_Severity"
    assert_includes headers, "Affected_Namespaces"
  end

  def test_csv_format_marks_cross_namespace_cycle_dependencies
    dependency_data = {
      "App::Models::User" => [{"Services::UserService" => ["validate"]}],
      "Services::UserService" => [{"App::Models::User" => ["find"]}]
    }
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

    csv_data = CSV.parse(result, headers: true)
    
    # Find the row for the cross-namespace dependency
    cycle_row = csv_data.find { |row| row["From"] == "App::Models::User" && row["To"] == "Services::UserService" }
    
    assert_equal "Yes", cycle_row["Cross_Namespace_Cycle"]
    assert_equal "high", cycle_row["Cycle_Severity"]
    assert_equal "App::Models, Services", cycle_row["Affected_Namespaces"]
  end

  def test_csv_format_handles_no_cross_namespace_cycles
    dependency_data = {"User" => [{"UserService" => ["validate"]}]}
    cross_namespace_cycles = []

    result = @adapter.format_with_architectural_analysis(
      dependency_data, 
      nil, 
      architectural_analysis: { cross_namespace_cycles: cross_namespace_cycles }
    )

    csv_data = CSV.parse(result, headers: true)
    
    # All rows should show "No" for cross-namespace cycles
    csv_data.each do |row|
      assert_equal "No", row["Cross_Namespace_Cycle"]
      assert_equal "", row["Cycle_Severity"]
      assert_equal "", row["Affected_Namespaces"]
    end
  end
end
