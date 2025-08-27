# frozen_string_literal: true

require "minitest/autorun"
require_relative "../test_helper"

# Tests for AnalysisResult class functionality including delegation,
# visualization coordination, and integration with various analysis components.
class AnalysisResultTest < Minitest::Test
  def test_analysis_result_converts_single_dependency_to_graph
    result = create_simple_analysis_result
    assert_simple_graph_structure(result)
  end

  def test_analysis_result_converts_multiple_dependencies_to_graph
    result = create_complex_analysis_result

    expected = {
      nodes: ["Player", "Enemy", "GameState", "Logger"],
      edges: [["Player", "Enemy"], ["Player", "GameState"], ["Player", "Logger"]]
    }

    assert_equal expected, result.to_graph
  end

  def test_analysis_result_handles_empty_dependency_data
    dependency_data = DependencyDataFactory.empty_dependency_data
    result = AnalyzerFactory.create_analysis_result(dependency_data)

    expected = AssertionFactory.empty_graph_structure

    assert_equal expected, result.to_graph
  end

  def test_analysis_result_handles_class_with_no_dependencies
    dependency_data = DependencyDataFactory.standalone_class_data
    result = AnalyzerFactory.create_analysis_result(dependency_data)

    graph = result.to_graph
    expected_graph = AssertionFactory.standalone_graph_structure
    assert_equal expected_graph, graph
  end

  def test_analysis_result_detects_circular_dependencies
    dependency_data = {
      "Player" => [{"Enemy" => ["take_damage"]}],
      "Enemy" => [{"Player" => ["take_damage"]}],
      "Game" => [{"Player" => ["new"]}]
    }
    result = RailsDependencyExplorer::Analysis::Pipeline::AnalysisResult.new(dependency_data)
    cycles = result.circular_dependencies

    expected_cycles = [["Player", "Enemy", "Player"]]
    assert_equal expected_cycles, cycles
  end

  def test_analysis_result_categorizes_rails_components
    dependency_data = DependencyDataFactory.rails_components_data
    result = AnalyzerFactory.create_analysis_result(dependency_data)
    components = result.rails_components

    expected_categories = AssertionFactory.rails_component_categories
    assert_includes components[:models], expected_categories[:models][0]
    assert_includes components[:controllers], expected_categories[:controllers][0]
    assert_includes components[:services], expected_categories[:services][0]
    assert_includes components[:other], expected_categories[:other][0]
  end

  def test_analysis_result_handles_no_circular_dependencies
    dependency_data = DependencyDataFactory.acyclic_dependency_graph
    result = AnalyzerFactory.create_analysis_result(dependency_data)
    cycles = result.circular_dependencies

    assert_equal AssertionFactory.no_cycles, cycles
  end

  def test_analysis_result_provides_rails_aware_graph
    dependency_data = {
      "User" => [
        {"ApplicationRecord" => [[]]},
        {"ActiveRecord::belongs_to" => ["Account"]},
        {"ActiveRecord::has_many" => ["Post"]}
      ]
    }
    result = RailsDependencyExplorer::Analysis::Pipeline::AnalysisResult.new(dependency_data)
    rails_graph = result.to_rails_graph

    expected_nodes = ["User", "ApplicationRecord", "Account", "Post"]
    expected_edges = [["User", "ApplicationRecord"], ["User", "Account"], ["User", "Post"]]

    assert_equal expected_nodes.sort, rails_graph[:nodes].sort
    assert_equal expected_edges.sort, rails_graph[:edges].sort
  end

  def test_analysis_result_provides_rails_aware_dot_format
    dependency_data = {
      "User" => [{"ActiveRecord::belongs_to" => ["Account"]}]
    }
    result = RailsDependencyExplorer::Analysis::Pipeline::AnalysisResult.new(dependency_data)
    rails_dot = result.to_rails_dot

    expected = "digraph dependencies {\n  \"User\" -> \"Account\";\n}"
    assert_equal expected, rails_dot
  end

  # Test to verify SRP compliance after refactoring
  def test_analysis_result_properly_separates_responsibilities_after_refactoring
    result = create_simple_analysis_result

    # Analysis coordination responsibilities (AnalysisResult's primary responsibility)
    assert_respond_to result, :statistics
    assert_respond_to result, :circular_dependencies
    assert_respond_to result, :dependency_depth
    assert_respond_to result, :rails_components
    assert_respond_to result, :activerecord_relationships
    assert_respond_to result, :rails_configuration_dependencies

    # Output formatting methods are still available through delegation
    # but the actual formatting logic is handled by AnalysisResultFormatter
    assert_respond_to result, :to_graph
    assert_respond_to result, :to_dot
    assert_respond_to result, :to_json
    assert_respond_to result, :to_html
    assert_respond_to result, :to_console
    assert_respond_to result, :to_csv
    assert_respond_to result, :to_rails_graph
    assert_respond_to result, :to_rails_dot

    # Verify that AnalysisResult now uses AnalysisResultFormatter internally
    formatter = result.send(:formatter)
    assert_instance_of RailsDependencyExplorer::Analysis::Pipeline::AnalysisResultFormatter, formatter

    # Verify that the formatter can work independently
    independent_formatter = RailsDependencyExplorer::Analysis::Pipeline::AnalysisResultFormatter.new(simple_dependency_data)
    assert_equal result.to_graph, independent_formatter.to_graph

    # This test verifies that AnalysisResult now follows SRP:
    # - AnalysisResult: coordinates analysis components
    # - AnalysisResultFormatter: handles output formatting
    assert true, "AnalysisResult now properly separates analysis coordination from output formatting"
  end
end
