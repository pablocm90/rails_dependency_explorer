# frozen_string_literal: true

require "minitest/autorun"
require_relative "../test_helper"
require_relative "../../lib/rails_dependency_explorer/analysis/architectural_analysis/architectural_cycle_formatter"

# Tests for ArchitecturalCycleFormatter focusing on formatting cycles
# into structured architectural analysis results.
class ArchitecturalCycleFormatterTest < Minitest::Test
  def test_format_single_cycle_with_default_severity
    cycle = ["App::Models::User", "Services::UserService", "App::Models::User"]
    
    result = RailsDependencyExplorer::Analysis::ArchitecturalAnalysis::ArchitecturalCycleFormatter.format_cycle(cycle)
    
    expected_result = {
      cycle: ["App::Models::User", "Services::UserService", "App::Models::User"],
      namespaces: ["App::Models", "Services"],
      severity: "high"
    }
    
    assert_equal expected_result, result
  end

  def test_format_single_cycle_with_custom_severity
    cycle = ["App::Models::User", "Services::UserService", "App::Models::User"]
    
    result = RailsDependencyExplorer::Analysis::ArchitecturalAnalysis::ArchitecturalCycleFormatter.format_cycle(cycle, severity: "medium")
    
    expected_result = {
      cycle: ["App::Models::User", "Services::UserService", "App::Models::User"],
      namespaces: ["App::Models", "Services"],
      severity: "medium"
    }
    
    assert_equal expected_result, result
  end

  def test_format_multiple_cycles_with_default_severity
    cycles = [
      ["App::Models::User", "Services::UserService", "App::Models::User"],
      ["User", "Services::UserService", "User"]
    ]
    
    results = RailsDependencyExplorer::Analysis::ArchitecturalAnalysis::ArchitecturalCycleFormatter.format_cycles(cycles)
    
    expected_results = [
      {
        cycle: ["App::Models::User", "Services::UserService", "App::Models::User"],
        namespaces: ["App::Models", "Services"],
        severity: "high"
      },
      {
        cycle: ["User", "Services::UserService", "User"],
        namespaces: ["", "Services"],
        severity: "high"
      }
    ]
    
    assert_equal expected_results, results
  end

  def test_format_multiple_cycles_with_custom_severity
    cycles = [
      ["App::Models::User", "Services::UserService", "App::Models::User"],
      ["User", "Services::UserService", "User"]
    ]
    
    results = RailsDependencyExplorer::Analysis::ArchitecturalAnalysis::ArchitecturalCycleFormatter.format_cycles(cycles, severity: "low")
    
    expected_results = [
      {
        cycle: ["App::Models::User", "Services::UserService", "App::Models::User"],
        namespaces: ["App::Models", "Services"],
        severity: "low"
      },
      {
        cycle: ["User", "Services::UserService", "User"],
        namespaces: ["", "Services"],
        severity: "low"
      }
    ]
    
    assert_equal expected_results, results
  end

  def test_format_empty_cycles_array
    cycles = []
    
    results = RailsDependencyExplorer::Analysis::ArchitecturalAnalysis::ArchitecturalCycleFormatter.format_cycles(cycles)
    
    assert_equal [], results
  end

  def test_format_complex_multi_namespace_cycle
    cycle = ["App::Models::User", "Services::UserService", "External::EmailService", "App::Models::User"]
    
    result = RailsDependencyExplorer::Analysis::ArchitecturalAnalysis::ArchitecturalCycleFormatter.format_cycle(cycle)
    
    expected_result = {
      cycle: ["App::Models::User", "Services::UserService", "External::EmailService", "App::Models::User"],
      namespaces: ["App::Models", "Services", "External"],
      severity: "high"
    }
    
    assert_equal expected_result, result
  end
end
