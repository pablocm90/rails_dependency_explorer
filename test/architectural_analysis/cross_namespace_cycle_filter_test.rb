# frozen_string_literal: true

require "minitest/autorun"
require_relative "../test_helper"
require_relative "../../lib/rails_dependency_explorer/analysis/architectural_analysis/cross_namespace_cycle_filter"

# Tests for CrossNamespaceCycleFilter focusing on identifying cycles
# that cross namespace boundaries for architectural analysis.
class CrossNamespaceCycleFilterTest < Minitest::Test
  def test_identifies_cross_namespace_cycle
    cycle = ["App::Models::User", "Services::UserService", "App::Models::User"]
    
    result = RailsDependencyExplorer::Analysis::ArchitecturalAnalysis::CrossNamespaceCycleFilter.cross_namespace_cycle?(cycle)
    assert result
  end

  def test_rejects_same_namespace_cycle
    cycle = ["App::Models::User", "App::Models::Profile", "App::Models::User"]
    
    result = RailsDependencyExplorer::Analysis::ArchitecturalAnalysis::CrossNamespaceCycleFilter.cross_namespace_cycle?(cycle)
    refute result
  end

  def test_identifies_complex_cross_namespace_cycle
    cycle = ["App::Models::User", "Services::UserService", "External::EmailService", "App::Models::User"]
    
    result = RailsDependencyExplorer::Analysis::ArchitecturalAnalysis::CrossNamespaceCycleFilter.cross_namespace_cycle?(cycle)
    assert result
  end

  def test_identifies_root_namespace_cross_cycle
    cycle = ["User", "Services::UserService", "User"]
    
    result = RailsDependencyExplorer::Analysis::ArchitecturalAnalysis::CrossNamespaceCycleFilter.cross_namespace_cycle?(cycle)
    assert result
  end

  def test_rejects_root_namespace_only_cycle
    cycle = ["User", "Profile", "User"]
    
    result = RailsDependencyExplorer::Analysis::ArchitecturalAnalysis::CrossNamespaceCycleFilter.cross_namespace_cycle?(cycle)
    refute result
  end

  def test_filters_mixed_cycles_collection
    cycles = [
      ["App::Models::User", "Services::UserService", "App::Models::User"], # cross-namespace
      ["App::Models::User", "App::Models::Profile", "App::Models::User"],  # same namespace
      ["User", "Services::UserService", "User"],                           # cross-namespace
      ["Services::UserService", "Services::EmailService", "Services::UserService"] # same namespace
    ]
    
    cross_namespace_cycles = RailsDependencyExplorer::Analysis::ArchitecturalAnalysis::CrossNamespaceCycleFilter.cross_namespace_cycles_only(cycles)
    
    expected_cycles = [
      ["App::Models::User", "Services::UserService", "App::Models::User"],
      ["User", "Services::UserService", "User"]
    ]
    
    assert_equal expected_cycles, cross_namespace_cycles
  end

  def test_returns_empty_array_when_no_cross_namespace_cycles
    cycles = [
      ["App::Models::User", "App::Models::Profile", "App::Models::User"],
      ["Services::UserService", "Services::EmailService", "Services::UserService"]
    ]
    
    cross_namespace_cycles = RailsDependencyExplorer::Analysis::ArchitecturalAnalysis::CrossNamespaceCycleFilter.cross_namespace_cycles_only(cycles)
    
    assert_equal [], cross_namespace_cycles
  end
end
