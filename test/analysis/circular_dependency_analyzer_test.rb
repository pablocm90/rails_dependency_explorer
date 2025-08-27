# frozen_string_literal: true

require "minitest/autorun"
require_relative "../test_helper"

# Tests for CircularDependencyAnalyzer including cycle detection algorithms,
# DFS traversal, and various circular dependency scenarios.
class CircularDependencyAnalyzerTest < Minitest::Test
  def test_finds_simple_circular_dependency
    dependency_data = DependencyDataFactory.simple_circular_dependency
    analyzer = AnalyzerFactory.create_circular_dependency_analyzer(dependency_data)
    cycles = analyzer.find_cycles

    expected_cycles = AssertionFactory.simple_circular_cycle
    assert_equal expected_cycles, cycles
  end

  def test_finds_no_cycles_in_acyclic_graph
    dependency_data = DependencyDataFactory.acyclic_dependency_graph
    analyzer = AnalyzerFactory.create_circular_dependency_analyzer(dependency_data)
    cycles = analyzer.find_cycles

    assert_equal AssertionFactory.no_cycles, cycles
  end

  def test_finds_complex_circular_dependency
    dependency_data = DependencyDataFactory.complex_circular_dependency
    analyzer = AnalyzerFactory.create_circular_dependency_analyzer(dependency_data)
    cycles = analyzer.find_cycles

    # Should find the cycle A -> B -> C -> A
    expected_cycles = AssertionFactory.complex_circular_cycle
    assert_equal expected_cycles, cycles
    cycle = cycles.first
    assert_includes cycle, "A"
    assert_includes cycle, "B"
    assert_includes cycle, "C"
    assert_equal 4, cycle.length # A -> B -> C -> A
  end

  def test_handles_empty_dependency_data
    dependency_data = {}

    analyzer = RailsDependencyExplorer::Analysis::Analyzers::CircularDependencyAnalyzer.new(dependency_data)
    cycles = analyzer.find_cycles

    assert_equal [], cycles
  end

  def test_handles_isolated_nodes
    dependency_data = {
      "Standalone" => []
    }

    analyzer = RailsDependencyExplorer::Analysis::Analyzers::CircularDependencyAnalyzer.new(dependency_data)
    cycles = analyzer.find_cycles

    assert_equal [], cycles
  end
end
