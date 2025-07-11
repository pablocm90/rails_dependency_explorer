# frozen_string_literal: true

require "minitest/autorun"
require_relative "../test_helper"

class HtmlFormatAdapterArchitecturalTest < Minitest::Test
  def setup
    @adapter = RailsDependencyExplorer::Output::HtmlFormatAdapter.new
  end

  def test_html_format_includes_architectural_analysis_section
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

    assert_includes result, "<h2>Architectural Analysis</h2>"
    assert_includes result, "<h3>Cross-Namespace Cycles</h3>"
    assert_includes result, "class='severity-high'"
    assert_includes result, "App::Models::User → Services::UserService → App::Models::User"
    assert_includes result, "Namespaces: App::Models, Services"
  end

  def test_html_format_shows_no_cycles_when_empty
    dependency_data = {"User" => [{"UserService" => ["validate"]}]}
    cross_namespace_cycles = []

    result = @adapter.format_with_architectural_analysis(
      dependency_data, 
      nil, 
      architectural_analysis: { cross_namespace_cycles: cross_namespace_cycles }
    )

    assert_includes result, "<h3>Cross-Namespace Cycles</h3>"
    assert_includes result, "class='no-issues'"
    assert_includes result, "✅ None detected"
  end

  def test_html_format_handles_multiple_cycles_with_styling
    dependency_data = {"User" => [{"UserService" => ["validate"]}]}
    cross_namespace_cycles = [
      {
        cycle: ["App::Models::User", "Services::UserService", "App::Models::User"],
        namespaces: ["App::Models", "Services"],
        severity: "high"
      },
      {
        cycle: ["Controllers::UsersController", "Models::User", "Controllers::UsersController"],
        namespaces: ["Controllers", "Models"],
        severity: "high"
      }
    ]

    result = @adapter.format_with_architectural_analysis(
      dependency_data, 
      nil, 
      architectural_analysis: { cross_namespace_cycles: cross_namespace_cycles }
    )

    assert_includes result, "2 cycles detected"
    assert_includes result, "App::Models::User → Services::UserService → App::Models::User"
    assert_includes result, "Controllers::UsersController → Models::User → Controllers::UsersController"
    # Should have CSS styling for architectural concerns
    assert_includes result, ".severity-high"
    assert_includes result, ".architectural-cycle"
  end
end
