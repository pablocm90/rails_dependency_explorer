# frozen_string_literal: true

require "minitest/autorun"
require_relative "../test_helper"

class DependencyStatisticsCalculatorTest < Minitest::Test
  def test_calculates_basic_statistics
    dependency_data = {
      "Player" => [{"Weapon" => ["damage"]}, {"Health" => ["decrease"]}],
      "Enemy" => [{"Weapon" => ["damage"]}]
    }

    calculator = RailsDependencyExplorer::Analysis::Analyzers::DependencyStatisticsCalculator.new(dependency_data)
    stats = calculator.calculate_statistics

    assert_equal 2, stats[:total_classes]
    assert_equal 2, stats[:total_dependencies]
    assert_equal "Weapon", stats[:most_used_dependency]

    expected_counts = {"Weapon" => 2, "Health" => 1}
    assert_equal expected_counts, stats[:dependency_counts]
  end

  def test_handles_single_class_single_dependency
    dependency_data = {
      "Player" => [{"Weapon" => ["damage"]}]
    }

    calculator = RailsDependencyExplorer::Analysis::Analyzers::DependencyStatisticsCalculator.new(dependency_data)
    stats = calculator.calculate_statistics

    assert_equal 1, stats[:total_classes]
    assert_equal 1, stats[:total_dependencies]
    assert_equal "Weapon", stats[:most_used_dependency]

    expected_counts = {"Weapon" => 1}
    assert_equal expected_counts, stats[:dependency_counts]
  end

  def test_handles_multiple_methods_on_same_dependency
    dependency_data = {
      "Player" => [{"Weapon" => ["damage", "reload", "aim"]}]
    }

    calculator = RailsDependencyExplorer::Analysis::Analyzers::DependencyStatisticsCalculator.new(dependency_data)
    stats = calculator.calculate_statistics

    assert_equal 1, stats[:total_classes]
    assert_equal 1, stats[:total_dependencies]
    assert_equal "Weapon", stats[:most_used_dependency]

    # Should count Weapon only once even with multiple methods
    expected_counts = {"Weapon" => 1}
    assert_equal expected_counts, stats[:dependency_counts]
  end

  def test_identifies_most_used_dependency_correctly
    dependency_data = {
      "PlayerA" => [{"Common" => ["method1"]}],
      "PlayerB" => [{"Common" => ["method2"]}],
      "PlayerC" => [{"Common" => ["method3"]}],
      "Enemy" => [{"Rare" => ["method"]}]
    }

    calculator = RailsDependencyExplorer::Analysis::Analyzers::DependencyStatisticsCalculator.new(dependency_data)
    stats = calculator.calculate_statistics

    assert_equal 4, stats[:total_classes]
    assert_equal 2, stats[:total_dependencies]
    assert_equal "Common", stats[:most_used_dependency]

    expected_counts = {"Common" => 3, "Rare" => 1}
    assert_equal expected_counts, stats[:dependency_counts]
  end

  def test_handles_empty_dependency_data
    dependency_data = {}

    calculator = RailsDependencyExplorer::Analysis::Analyzers::DependencyStatisticsCalculator.new(dependency_data)
    stats = calculator.calculate_statistics

    assert_equal 0, stats[:total_classes]
    assert_equal 0, stats[:total_dependencies]
    assert_nil stats[:most_used_dependency]
    assert_equal({}, stats[:dependency_counts])
  end

  def test_handles_classes_with_no_dependencies
    dependency_data = {
      "Standalone" => []
    }

    calculator = RailsDependencyExplorer::Analysis::Analyzers::DependencyStatisticsCalculator.new(dependency_data)
    stats = calculator.calculate_statistics

    assert_equal 1, stats[:total_classes]
    assert_equal 0, stats[:total_dependencies]
    assert_nil stats[:most_used_dependency]
    assert_equal({}, stats[:dependency_counts])
  end

  def test_handles_mixed_classes_with_and_without_dependencies
    dependency_data = {
      "Active" => [{"Helper" => ["method"]}],
      "Standalone" => []
    }

    calculator = RailsDependencyExplorer::Analysis::Analyzers::DependencyStatisticsCalculator.new(dependency_data)
    stats = calculator.calculate_statistics

    assert_equal 2, stats[:total_classes]
    assert_equal 1, stats[:total_dependencies]
    assert_equal "Helper", stats[:most_used_dependency]

    expected_counts = {"Helper" => 1}
    assert_equal expected_counts, stats[:dependency_counts]
  end
end
