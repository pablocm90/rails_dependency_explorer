# frozen_string_literal: true

require "minitest/autorun"
require_relative "../test_helper"
require_relative "../../lib/rails_dependency_explorer/architectural_analysis/cross_namespace_cycle_analyzer"

# Tests for CrossNamespaceCycleAnalyzer focusing on detecting circular dependencies
# that cross namespace/module boundaries, which are architectural red flags.
# These cycles indicate poor separation of concerns and tight coupling between modules.
class CrossNamespaceCycleAnalyzerTest < Minitest::Test
  def test_cross_namespace_circular_dependency_detection
    dependency_data = simple_cross_namespace_cycle_data
    expected_cycles = [expected_simple_cross_namespace_cycle]

    assert_cross_namespace_cycles expected_cycles, dependency_data
  end

  def test_ignores_same_namespace_cycles
    dependency_data = same_namespace_cycle_data
    assert_cross_namespace_cycles [], dependency_data
  end

  def test_detects_complex_cross_namespace_cycles
    dependency_data = complex_cross_namespace_cycle_data
    expected_cycles = [expected_complex_cross_namespace_cycle]

    assert_cross_namespace_cycles expected_cycles, dependency_data
  end

  def test_handles_classes_without_namespaces
    dependency_data = mixed_namespace_cycle_data
    expected_cycles = [expected_mixed_namespace_cycle]

    assert_cross_namespace_cycles expected_cycles, dependency_data
  end

  def test_handles_empty_dependency_data
    assert_cross_namespace_cycles [], {}
  end

  def test_handles_acyclic_cross_namespace_dependencies
    dependency_data = acyclic_cross_namespace_data
    assert_cross_namespace_cycles [], dependency_data
  end

  private

  def assert_cross_namespace_cycles(expected_cycles, dependency_data)
    analyzer = RailsDependencyExplorer::ArchitecturalAnalysis::CrossNamespaceCycleAnalyzer.new(dependency_data)
    cross_namespace_cycles = analyzer.find_cross_namespace_cycles
    assert_equal expected_cycles, cross_namespace_cycles
  end

  # Test data helpers
  def simple_cross_namespace_cycle_data
    {
      "App::Models::User" => [{"Services::UserService" => ["validate"]}],
      "Services::UserService" => [{"App::Models::User" => ["find"]}]
    }
  end

  def same_namespace_cycle_data
    {
      "App::Models::User" => [{"App::Models::Profile" => ["validate"]}],
      "App::Models::Profile" => [{"App::Models::User" => ["find"]}]
    }
  end

  def complex_cross_namespace_cycle_data
    {
      "App::Models::User" => [{"Services::UserService" => ["process"]}],
      "Services::UserService" => [{"External::EmailService" => ["send"]}],
      "External::EmailService" => [{"App::Models::User" => ["email"]}]
    }
  end

  def mixed_namespace_cycle_data
    {
      "User" => [{"Services::UserService" => ["validate"]}],
      "Services::UserService" => [{"User" => ["find"]}]
    }
  end

  def acyclic_cross_namespace_data
    {
      "App::Models::User" => [{"Services::UserService" => ["validate"]}],
      "Services::UserService" => [{"External::EmailService" => ["send"]}]
    }
  end

  # Expected result helpers
  def expected_simple_cross_namespace_cycle
    {
      cycle: ["App::Models::User", "Services::UserService", "App::Models::User"],
      namespaces: ["App::Models", "Services"],
      severity: "high"
    }
  end

  def expected_complex_cross_namespace_cycle
    {
      cycle: ["App::Models::User", "Services::UserService", "External::EmailService", "App::Models::User"],
      namespaces: ["App::Models", "Services", "External"],
      severity: "high"
    }
  end

  def expected_mixed_namespace_cycle
    {
      cycle: ["User", "Services::UserService", "User"],
      namespaces: ["", "Services"],
      severity: "high"
    }
  end
end
