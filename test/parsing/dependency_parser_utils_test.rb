# frozen_string_literal: true

require "minitest/autorun"
require_relative "../test_helper"

# Tests for DependencyParserUtils class focusing on static utility methods.
# Verifies that the utility methods handle class name extraction and
# dependency accumulation correctly as standalone operations.
class DependencyParserUtilsTest < Minitest::Test
  def test_extract_class_name_extracts_simple_class_name
    ruby_code = <<~RUBY
      class Player
        def attack
          Enemy.health -= 10
        end
      end
    RUBY

    parser = Parser::CurrentRuby
    ast = parser.parse(ruby_code)
    class_nodes = find_class_nodes(ast)
    class_name = RailsDependencyExplorer::Parsing::DependencyParserUtils.extract_class_name(class_nodes.first)

    assert_equal "Player", class_name
  end

  def test_extract_class_name_extracts_module_name
    ruby_code = <<~RUBY
      module Validatable
        def self.check(object)
          Logger.info("Validating object")
        end
      end
    RUBY

    parser = Parser::CurrentRuby
    ast = parser.parse(ruby_code)
    class_nodes = find_class_nodes(ast)
    class_name = RailsDependencyExplorer::Parsing::DependencyParserUtils.extract_class_name(class_nodes.first)

    assert_equal "Validatable", class_name
  end

  def test_extract_class_name_returns_empty_for_invalid_node
    # Create a mock node without proper structure
    mock_node = Object.new
    def mock_node.children
      [nil]
    end

    class_name = RailsDependencyExplorer::Parsing::DependencyParserUtils.extract_class_name(mock_node)
    assert_equal "", class_name
  end

  def test_accumulate_visited_dependencies_handles_hash_dependencies
    accumulator = RailsDependencyExplorer::Parsing::DependencyAccumulator.new
    dependencies = {"Enemy" => ["health", "take_damage"]}

    RailsDependencyExplorer::Parsing::DependencyParserUtils.accumulate_visited_dependencies(dependencies, accumulator)

    result = accumulator.collection.to_grouped_array
    expected = [{"Enemy" => ["health", "take_damage"]}]
    assert_equal expected, result
  end

  def test_accumulate_visited_dependencies_handles_array_of_hash_dependencies
    accumulator = RailsDependencyExplorer::Parsing::DependencyAccumulator.new
    dependencies = [
      {"Enemy" => ["health"]},
      {"Logger" => ["info"]}
    ]

    RailsDependencyExplorer::Parsing::DependencyParserUtils.accumulate_visited_dependencies(dependencies, accumulator)

    result = accumulator.collection.to_grouped_array
    expected = [
      {"Enemy" => ["health"]},
      {"Logger" => ["info"]}
    ]
    assert_equal expected, result
  end

  def test_accumulate_visited_dependencies_handles_string_dependencies
    accumulator = RailsDependencyExplorer::Parsing::DependencyAccumulator.new
    dependencies = "SomeConstant"

    RailsDependencyExplorer::Parsing::DependencyParserUtils.accumulate_visited_dependencies(dependencies, accumulator)

    result = accumulator.collection.to_grouped_array
    # String constants create entries with empty array as method name (matches original behavior)
    expected = [{"SomeConstant" => [[]]}]
    assert_equal expected, result
  end

  def test_accumulate_visited_dependencies_handles_mixed_array
    accumulator = RailsDependencyExplorer::Parsing::DependencyAccumulator.new
    dependencies = [
      {"Enemy" => ["health"]},
      "SomeConstant",
      {"Logger" => ["info"]}
    ]

    RailsDependencyExplorer::Parsing::DependencyParserUtils.accumulate_visited_dependencies(dependencies, accumulator)

    result = accumulator.collection.to_grouped_array
    # String constants create entries with empty array as method name (matches original behavior)
    expected = [
      {"Enemy" => ["health"]},
      {"SomeConstant" => [[]]},
      {"Logger" => ["info"]}
    ]
    assert_equal expected, result
  end

  def test_accumulate_visited_dependencies_handles_nested_arrays
    accumulator = RailsDependencyExplorer::Parsing::DependencyAccumulator.new
    dependencies = [
      [{"Enemy" => ["health"]}],
      [{"Logger" => ["info"]}, "SomeConstant"]
    ]

    RailsDependencyExplorer::Parsing::DependencyParserUtils.accumulate_visited_dependencies(dependencies, accumulator)

    result = accumulator.collection.to_grouped_array
    # String constants create entries with empty array as method name (matches original behavior)
    expected = [
      {"Enemy" => ["health"]},
      {"Logger" => ["info"]},
      {"SomeConstant" => [[]]}
    ]
    assert_equal expected, result
  end

  def test_accumulate_visited_dependencies_handles_empty_array
    accumulator = RailsDependencyExplorer::Parsing::DependencyAccumulator.new
    dependencies = []

    RailsDependencyExplorer::Parsing::DependencyParserUtils.accumulate_visited_dependencies(dependencies, accumulator)

    result = accumulator.collection.to_grouped_array
    expected = []
    assert_equal expected, result
  end

  private

  def find_class_nodes(node)
    return [] unless node.respond_to?(:type)

    class_nodes = []
    class_nodes << node if node.type == :class || node.type == :module

    if node.respond_to?(:children) && node.children
      node.children.each do |child|
        class_nodes.concat(find_class_nodes(child))
      end
    end

    class_nodes
  end
end
