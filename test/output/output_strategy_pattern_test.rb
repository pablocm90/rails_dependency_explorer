# frozen_string_literal: true

require "minitest/autorun"
require_relative "../test_helper"

# Tests for Output Strategy Pattern implementation to reduce DependencyVisualizer method proliferation.
# Verifies that output formatting can be handled through pluggable strategy objects.
# Part of Phase 4.1 output strategy hierarchy (Tidy First - Structural changes).
class OutputStrategyPatternTest < Minitest::Test
  def setup
    @dependency_data = {
      "Player" => [{"Enemy" => ["health"]}, {"Weapon" => ["damage"]}],
      "Enemy" => [{"Health" => ["decrease"]}]
    }
    @statistics = {
      total_classes: 3,
      total_dependencies: 3,
      most_used_dependency: "Enemy"
    }
    @visualizer = RailsDependencyExplorer::Output::DependencyVisualizer.new
  end

  def test_output_strategy_base_class_exists
    # Test that OutputStrategy base class exists and defines required interface
    # This test will fail until we create the base strategy class
    
    assert defined?(RailsDependencyExplorer::Output::OutputStrategy),
      "OutputStrategy base class should be defined"
    
    strategy = RailsDependencyExplorer::Output::OutputStrategy.new
    assert_respond_to strategy, :format, "OutputStrategy should define format method"
  end

  def test_json_output_strategy_exists_and_works
    # Test that JsonOutputStrategy exists and can format data
    # This test will fail until we create the JsonOutputStrategy class
    
    assert defined?(RailsDependencyExplorer::Output::JsonOutputStrategy),
      "JsonOutputStrategy class should be defined"
    
    strategy = RailsDependencyExplorer::Output::JsonOutputStrategy.new
    result = strategy.format(@dependency_data, @statistics)
    
    assert_kind_of String, result
    assert_match(/"dependencies"/, result)
    assert_match(/"statistics"/, result)
  end

  def test_html_output_strategy_exists_and_works
    # Test that HtmlOutputStrategy exists and can format data
    # This test will fail until we create the HtmlOutputStrategy class
    
    assert defined?(RailsDependencyExplorer::Output::HtmlOutputStrategy),
      "HtmlOutputStrategy class should be defined"
    
    strategy = RailsDependencyExplorer::Output::HtmlOutputStrategy.new
    result = strategy.format(@dependency_data, @statistics)
    
    assert_kind_of String, result
    assert_match(/<html>/, result)
    assert_match(/Dependencies Report/, result)
  end

  def test_dot_output_strategy_exists_and_works
    # Test that DotOutputStrategy exists and can format data
    # This test will fail until we create the DotOutputStrategy class
    
    assert defined?(RailsDependencyExplorer::Output::DotOutputStrategy),
      "DotOutputStrategy class should be defined"
    
    strategy = RailsDependencyExplorer::Output::DotOutputStrategy.new
    result = strategy.format(@dependency_data)
    
    assert_kind_of String, result
    assert_match(/digraph dependencies/, result)
    assert_match(/Player.*->.*Enemy/, result)
  end

  def test_csv_output_strategy_exists_and_works
    # Test that CsvOutputStrategy exists and can format data
    # This test will fail until we create the CsvOutputStrategy class
    
    assert defined?(RailsDependencyExplorer::Output::CsvOutputStrategy),
      "CsvOutputStrategy class should be defined"
    
    strategy = RailsDependencyExplorer::Output::CsvOutputStrategy.new
    result = strategy.format(@dependency_data, @statistics)
    
    assert_kind_of String, result
    assert_match(/Source,Target,Methods/, result)
    assert_match(/Player,Enemy/, result)
  end

  def test_console_output_strategy_exists_and_works
    # Test that ConsoleOutputStrategy exists and can format data
    # This test will fail until we create the ConsoleOutputStrategy class
    
    assert defined?(RailsDependencyExplorer::Output::ConsoleOutputStrategy),
      "ConsoleOutputStrategy class should be defined"
    
    strategy = RailsDependencyExplorer::Output::ConsoleOutputStrategy.new
    result = strategy.format(@dependency_data)
    
    assert_kind_of String, result
    assert_match(/Player/, result)
    assert_match(/Enemy/, result)
  end

  def test_dependency_visualizer_supports_strategy_pattern
    # Test that DependencyVisualizer can use strategy objects instead of direct methods
    # This test will fail until we implement the strategy pattern in DependencyVisualizer
    
    json_strategy = RailsDependencyExplorer::Output::JsonOutputStrategy.new
    html_strategy = RailsDependencyExplorer::Output::HtmlOutputStrategy.new
    
    # Should be able to format using strategy objects
    json_result = @visualizer.format(@dependency_data, strategy: json_strategy, statistics: @statistics)
    html_result = @visualizer.format(@dependency_data, strategy: html_strategy, statistics: @statistics)
    
    # Results should be in correct formats
    assert_match(/"dependencies"/, json_result)
    assert_match(/<html>/, html_result)
  end

  def test_dependency_visualizer_maintains_backward_compatibility
    # Test that existing methods still work after strategy pattern implementation
    # This ensures we don't break existing code
    
    # Existing methods should still work
    json_result = @visualizer.to_json(@dependency_data, @statistics)
    html_result = @visualizer.to_html(@dependency_data, @statistics)
    dot_result = @visualizer.to_dot(@dependency_data)
    csv_result = @visualizer.to_csv(@dependency_data, @statistics)
    console_result = @visualizer.to_console(@dependency_data)
    
    # Results should be in correct formats
    assert_match(/"dependencies"/, json_result)
    assert_match(/<html>/, html_result)
    assert_match(/digraph dependencies/, dot_result)
    assert_match(/Source,Target,Methods/, csv_result)
    assert_kind_of String, console_result
  end

  def test_strategy_pattern_supports_architectural_analysis
    # Test that strategy pattern supports architectural analysis enhancement
    # This test will fail until we implement architectural analysis support in strategies
    
    architectural_analysis = {
      cross_namespace_cycles: [
        {
          cycle: ["Player", "Enemy", "Player"],
          severity: "high",
          namespaces: ["Game", "Combat"]
        }
      ]
    }
    
    json_strategy = RailsDependencyExplorer::Output::JsonOutputStrategy.new
    result = json_strategy.format(@dependency_data, @statistics, architectural_analysis: architectural_analysis)
    
    assert_match(/"architectural_analysis"/, result)
    assert_match(/"cross_namespace_cycles"/, result)
  end

  def test_strategy_pattern_reduces_visualizer_method_count
    # Test that strategy pattern reduces the number of methods in DependencyVisualizer
    # This is a meta-test to ensure we're actually solving the method proliferation problem

    visualizer_methods = RailsDependencyExplorer::Output::DependencyVisualizer.instance_methods(false)

    # After implementing strategy pattern, we should have fewer format-specific methods
    # The exact number will depend on implementation, but we should have:
    # - A generic format method that accepts strategies
    # - Backward compatibility methods (can be reduced over time)
    # - Core coordination methods

    # Should have the new strategy-based format method
    assert_includes visualizer_methods, :format

    # Method count should be reasonable (not excessive)
    # This is a guideline - adjust based on actual implementation needs
    assert visualizer_methods.size < 20, "DependencyVisualizer should not have excessive methods. Current count: #{visualizer_methods.size}"
  end

  def test_dependency_visualizer_provides_strategy_factory_method
    # Test that DependencyVisualizer provides a convenient way to create strategies
    # This makes the strategy pattern easier to use

    # Should be able to create strategies using factory method
    json_strategy = @visualizer.create_strategy(:json)
    html_strategy = @visualizer.create_strategy(:html)
    dot_strategy = @visualizer.create_strategy(:dot)
    csv_strategy = @visualizer.create_strategy(:csv)
    console_strategy = @visualizer.create_strategy(:console)

    # Should create correct strategy types
    assert_instance_of RailsDependencyExplorer::Output::JsonOutputStrategy, json_strategy
    assert_instance_of RailsDependencyExplorer::Output::HtmlOutputStrategy, html_strategy
    assert_instance_of RailsDependencyExplorer::Output::DotOutputStrategy, dot_strategy
    assert_instance_of RailsDependencyExplorer::Output::CsvOutputStrategy, csv_strategy
    assert_instance_of RailsDependencyExplorer::Output::ConsoleOutputStrategy, console_strategy

    # Should raise error for unknown format
    assert_raises(ArgumentError) do
      @visualizer.create_strategy(:unknown)
    end
  end
end
