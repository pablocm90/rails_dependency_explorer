# frozen_string_literal: true

require "minitest/autorun"
require_relative "../test_helper"

class HtmlFormatAdapterTest < Minitest::Test
  def setup
    @adapter = RailsDependencyExplorer::Output::HtmlFormatAdapter.new
  end

  def test_html_format_adapter_generates_valid_html_structure
    dependency_data = {"Player" => [{"Enemy" => ["health"]}]}
    statistics = {
      total_classes: 1,
      total_dependencies: 1,
      most_used_dependency: "Enemy"
    }

    result = @adapter.format(dependency_data, statistics)

    # Verify essential HTML structure with minimal assertions
    assert_includes result, "<!DOCTYPE html>"
    assert_includes result, "<title>Dependencies Report</title>"
    assert result.include?("<html>") && result.include?("</html>")
  end

  def test_html_format_adapter_includes_dependency_information
    dependency_data = {"Player" => [{"Enemy" => ["health"]}, {"Logger" => ["info"]}]}

    result = @adapter.format(dependency_data)

    assert_includes result, "Player"
    assert_includes result, "Enemy"
    assert_includes result, "Logger"
    assert_includes result, "→ Enemy"
    assert_includes result, "→ Logger"
  end

  def test_html_format_adapter_includes_statistics
    dependency_data = {"Player" => [{"Enemy" => ["health"]}]}
    statistics = {
      total_classes: 1,
      total_dependencies: 1,
      most_used_dependency: "Enemy"
    }

    result = @adapter.format(dependency_data, statistics)

    # Verify key statistics are present with consolidated assertions
    assert_includes result, "Total Classes"
    assert_includes result, "Most Used Dependency"
    assert_includes result, "Enemy"
  end

  def test_html_format_adapter_handles_empty_dependency_data
    dependency_data = {}

    result = @adapter.format(dependency_data)

    # Verify essential empty state messaging
    assert_includes result, "Dependencies Report"
    assert_includes result, "No dependencies found"
  end

  def test_html_format_adapter_handles_class_with_no_dependencies
    dependency_data = {"Player" => []}

    result = @adapter.format(dependency_data)

    assert_includes result, "Player"
    assert_includes result, "No dependencies"
  end

  def test_html_format_adapter_deduplicates_dependencies
    dependency_data = {
      "Player" => [{"Enemy" => ["health"]}, {"Enemy" => ["damage"]}]
    }

    result = @adapter.format(dependency_data)

    # Should only show Enemy once
    enemy_count = result.scan(/→ Enemy/).length
    assert_equal 1, enemy_count
  end

  def test_html_format_adapter_includes_css_styling
    dependency_data = {"Player" => [{"Enemy" => ["health"]}]}

    result = @adapter.format(dependency_data)

    # Verify CSS styling is present
    assert_includes result, "<style>"
    assert_includes result, ".class-name"
  end
end
