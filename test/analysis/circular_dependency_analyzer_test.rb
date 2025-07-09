# frozen_string_literal: true

require "minitest/autorun"
require_relative "../test_helper"

# Tests for CircularDependencyAnalyzer including cycle detection algorithms,
# DFS traversal, and various circular dependency scenarios.
class CircularDependencyAnalyzerTest < Minitest::Test
  def test_finds_simple_circular_dependency
    dependency_data = {
      "Player" => [{"Enemy" => ["take_damage"]}],
      "Enemy" => [{"Player" => ["take_damage"]}]
    }

    analyzer = RailsDependencyExplorer::Analysis::CircularDependencyAnalyzer.new(dependency_data)
    cycles = analyzer.find_cycles

    expected_cycles = [["Player", "Enemy", "Player"]]
    assert_equal expected_cycles, cycles
  end

  def test_finds_no_cycles_in_acyclic_graph
    dependency_data = {
      "Player" => [{"Enemy" => ["take_damage"]}],
      "Game" => [{"Player" => ["new"]}]
    }

    analyzer = RailsDependencyExplorer::Analysis::CircularDependencyAnalyzer.new(dependency_data)
    cycles = analyzer.find_cycles

    assert_equal [], cycles
  end

  def test_finds_complex_circular_dependency
    dependency_data = {
      "A" => [{"B" => ["method"]}],
      "B" => [{"C" => ["method"]}],
      "C" => [{"A" => ["method"]}]
    }

    analyzer = RailsDependencyExplorer::Analysis::CircularDependencyAnalyzer.new(dependency_data)
    cycles = analyzer.find_cycles

    # Should find the cycle A -> B -> C -> A
    assert_equal 1, cycles.length
    cycle = cycles.first
    assert_includes cycle, "A"
    assert_includes cycle, "B"
    assert_includes cycle, "C"
    assert_equal 4, cycle.length # A -> B -> C -> A
  end

  def test_handles_empty_dependency_data
    dependency_data = {}

    analyzer = RailsDependencyExplorer::Analysis::CircularDependencyAnalyzer.new(dependency_data)
    cycles = analyzer.find_cycles

    assert_equal [], cycles
  end

  def test_handles_isolated_nodes
    dependency_data = {
      "Standalone" => []
    }

    analyzer = RailsDependencyExplorer::Analysis::CircularDependencyAnalyzer.new(dependency_data)
    cycles = analyzer.find_cycles

    assert_equal [], cycles
  end
end
