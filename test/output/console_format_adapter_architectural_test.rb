# frozen_string_literal: true

require "minitest/autorun"
require_relative "../test_helper"

class ConsoleFormatAdapterArchitecturalTest < Minitest::Test
  def setup
    @adapter = RailsDependencyExplorer::Output::ConsoleFormatAdapter
  end

  def test_console_format_includes_cross_namespace_cycles_section
    cross_namespace_cycles = [
      {
        cycle: ["App::Models::User", "Services::UserService", "App::Models::User"],
        namespaces: ["App::Models", "Services"],
        severity: "high"
      }
    ]

    result = @adapter.format_architectural_analysis(cross_namespace_cycles: cross_namespace_cycles)

    assert_includes result, "Cross-Namespace Cycles:"
    assert_includes result, "⚠️  HIGH SEVERITY"
    assert_includes result, "App::Models::User -> Services::UserService -> App::Models::User"
    assert_includes result, "Namespaces: App::Models, Services"
  end

  def test_console_format_shows_no_cross_namespace_cycles_when_empty
    cross_namespace_cycles = []

    result = @adapter.format_architectural_analysis(cross_namespace_cycles: cross_namespace_cycles)

    assert_includes result, "Cross-Namespace Cycles:"
    assert_includes result, "✅ None detected"
  end

  def test_console_format_handles_multiple_cross_namespace_cycles
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

    result = @adapter.format_architectural_analysis(cross_namespace_cycles: cross_namespace_cycles)

    assert_includes result, "⚠️  HIGH SEVERITY (2 cycles detected)"
    assert_includes result, "App::Models::User -> Services::UserService -> App::Models::User"
    assert_includes result, "Controllers::UsersController -> Models::User -> Controllers::UsersController"
  end
end
