# frozen_string_literal: true

require "minitest/autorun"
require "json"
require_relative "../test_helper"

class JsonFormatAdapterTest < Minitest::Test
  def setup
    @adapter = RailsDependencyExplorer::Output::JsonFormatAdapter.new
  end

  def test_json_format_adapter_formats_single_dependency_with_statistics
    dependency_data = {"Player" => [{"Enemy" => ["health"]}]}
    statistics = {
      total_classes: 1,
      total_dependencies: 1,
      most_used_dependency: "Enemy",
      dependency_counts: {"Enemy" => 1}
    }

    result = @adapter.format(dependency_data, statistics)
    parsed = JSON.parse(result)

    expected_dependencies = {"Player" => ["Enemy"]}
    expected_statistics = {
      "total_classes" => 1,
      "total_dependencies" => 1,
      "most_used_dependency" => "Enemy",
      "dependency_counts" => {"Enemy" => 1}
    }

    assert_equal expected_dependencies, parsed["dependencies"]
    assert_equal expected_statistics, parsed["statistics"]
  end

  def test_json_format_adapter_formats_multiple_dependencies_with_statistics
    dependency_data = {"Player" => [{"Enemy" => ["health"]}, {"Logger" => ["info"]}]}
    statistics = {
      total_classes: 1,
      total_dependencies: 2,
      most_used_dependency: "Enemy",
      dependency_counts: {"Enemy" => 1, "Logger" => 1}
    }

    result = @adapter.format(dependency_data, statistics)
    parsed = JSON.parse(result)

    expected_dependencies = {"Player" => ["Enemy", "Logger"]}
    expected_statistics = {
      "total_classes" => 1,
      "total_dependencies" => 2,
      "most_used_dependency" => "Enemy",
      "dependency_counts" => {"Enemy" => 1, "Logger" => 1}
    }

    assert_equal expected_dependencies, parsed["dependencies"]
    assert_equal expected_statistics, parsed["statistics"]
  end

  def test_json_format_adapter_formats_without_statistics
    dependency_data = {"Player" => [{"Enemy" => ["health"]}]}

    result = @adapter.format(dependency_data)
    parsed = JSON.parse(result)

    expected_dependencies = {"Player" => ["Enemy"]}
    assert_equal expected_dependencies, parsed["dependencies"]
    assert_nil parsed["statistics"]
  end

  def test_json_format_adapter_handles_empty_dependency_data
    dependency_data = {}

    result = @adapter.format(dependency_data)
    parsed = JSON.parse(result)

    expected_dependencies = {}
    assert_equal expected_dependencies, parsed["dependencies"]
    assert_nil parsed["statistics"]
  end

  def test_json_format_adapter_deduplicates_dependencies
    dependency_data = {
      "Player" => [{"Enemy" => ["health"]}, {"Enemy" => ["damage"]}]
    }

    result = @adapter.format(dependency_data)
    parsed = JSON.parse(result)

    expected_dependencies = {"Player" => ["Enemy"]}
    assert_equal expected_dependencies, parsed["dependencies"]
  end

  def test_json_format_adapter_handles_multiple_classes
    dependency_data = {
      "Player" => [{"Enemy" => ["health"]}],
      "Enemy" => [{"Logger" => ["debug"]}]
    }

    result = @adapter.format(dependency_data)
    parsed = JSON.parse(result)

    expected_dependencies = {
      "Player" => ["Enemy"],
      "Enemy" => ["Logger"]
    }
    assert_equal expected_dependencies, parsed["dependencies"]
  end
end
