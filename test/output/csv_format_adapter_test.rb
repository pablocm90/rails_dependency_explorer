# frozen_string_literal: true

require "minitest/autorun"
require_relative "../test_helper"

class CsvFormatAdapterTest < Minitest::Test
  def setup
    @adapter = RailsDependencyExplorer::Output::CsvFormatAdapter.new
  end

  def test_csv_format_adapter_formats_single_dependency
    dependency_data = {"Player" => [{"Enemy" => ["health"]}]}

    result = @adapter.format(dependency_data)
    lines = result.split("\n")

    assert_equal "Source,Target,Methods", lines.first
    assert_equal "Player,Enemy,health", lines.last
  end

  def test_csv_format_adapter_formats_multiple_dependencies
    dependency_data = {
      "Player" => [
        {"Enemy" => ["take_damage", "health"]},
        {"GameState" => ["current"]},
        {"Logger" => ["info"]}
      ]
    }

    result = @adapter.format(dependency_data)
    lines = result.split("\n")

    assert_equal "Source,Target,Methods", lines.first
    assert_includes result, "Player,Enemy,take_damage;health"
    assert_includes result, "Player,GameState,current"
    assert_includes result, "Player,Logger,info"
  end

  def test_csv_format_adapter_handles_empty_dependency_data
    dependency_data = {}

    result = @adapter.format(dependency_data)

    assert_equal "Source,Target,Methods", result
  end

  def test_csv_format_adapter_handles_class_with_no_dependencies
    dependency_data = {"Standalone" => []}

    result = @adapter.format(dependency_data)

    assert_equal "Source,Target,Methods", result
  end

  def test_csv_format_adapter_ignores_statistics_parameter
    dependency_data = {"Player" => [{"Enemy" => ["health"]}]}
    statistics = {total_classes: 2, total_dependencies: 1}

    result = @adapter.format(dependency_data, statistics)
    lines = result.split("\n")

    # Statistics should not affect CSV output
    assert_equal "Source,Target,Methods", lines.first
    assert_equal "Player,Enemy,health", lines.last
  end
end
