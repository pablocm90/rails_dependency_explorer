# frozen_string_literal: true

require "minitest/autorun"
require_relative "../test_helper"

class DependencyDepthAnalyzerTest < Minitest::Test
  def test_calculates_simple_dependency_depth
    dependency_data = {
      "Player" => [{"Weapon" => ["damage"]}],
      "Weapon" => []
    }

    analyzer = RailsDependencyExplorer::Analysis::DependencyDepthAnalyzer.new(dependency_data)
    depths = analyzer.calculate_depth

    expected_depths = {
      "Player" => 0,  # Root level - no one depends on it
      "Weapon" => 1   # One level deep - Player depends on it
    }
    assert_equal expected_depths, depths
  end

  def test_calculates_complex_dependency_chain
    dependency_data = {
      "Player" => [{"Weapon" => ["damage"]}],
      "Weapon" => [{"Material" => ["hardness"]}],
      "Material" => [{"Config" => ["base_hardness"]}],
      "Config" => []
    }

    analyzer = RailsDependencyExplorer::Analysis::DependencyDepthAnalyzer.new(dependency_data)
    depths = analyzer.calculate_depth

    expected_depths = {
      "Player" => 0,    # Root level
      "Weapon" => 1,    # Player depends on it
      "Material" => 2,  # Weapon depends on it
      "Config" => 3     # Material depends on it
    }
    assert_equal expected_depths, depths
  end

  def test_handles_multiple_root_nodes
    dependency_data = {
      "PlayerA" => [{"Weapon" => ["damage"]}],
      "PlayerB" => [{"Weapon" => ["damage"]}],
      "Weapon" => []
    }

    analyzer = RailsDependencyExplorer::Analysis::DependencyDepthAnalyzer.new(dependency_data)
    depths = analyzer.calculate_depth

    expected_depths = {
      "PlayerA" => 0,  # Root level
      "PlayerB" => 0,  # Root level
      "Weapon" => 1    # Both players depend on it
    }
    assert_equal expected_depths, depths
  end

  def test_handles_branching_dependencies
    dependency_data = {
      "Game" => [{"Player" => ["new"]}, {"Enemy" => ["spawn"]}],
      "Player" => [{"Weapon" => ["equip"]}],
      "Enemy" => [{"Weapon" => ["equip"]}],
      "Weapon" => []
    }

    analyzer = RailsDependencyExplorer::Analysis::DependencyDepthAnalyzer.new(dependency_data)
    depths = analyzer.calculate_depth

    expected_depths = {
      "Game" => 0,     # Root level
      "Player" => 1,   # Game depends on it
      "Enemy" => 1,    # Game depends on it
      "Weapon" => 2    # Both Player and Enemy depend on it
    }
    assert_equal expected_depths, depths
  end

  def test_handles_empty_dependency_data
    dependency_data = {}

    analyzer = RailsDependencyExplorer::Analysis::DependencyDepthAnalyzer.new(dependency_data)
    depths = analyzer.calculate_depth

    assert_equal({}, depths)
  end

  def test_handles_isolated_nodes
    dependency_data = {
      "Standalone" => []
    }

    analyzer = RailsDependencyExplorer::Analysis::DependencyDepthAnalyzer.new(dependency_data)
    depths = analyzer.calculate_depth

    expected_depths = {
      "Standalone" => 0  # Root level - no dependencies
    }
    assert_equal expected_depths, depths
  end
end
