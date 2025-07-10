# frozen_string_literal: true

require "minitest/autorun"
require_relative "../test_helper"

# Tests for ASTProcessor class focusing solely on AST processing operations.
# Verifies that the processor handles AST building, class discovery, and
# class name extraction without being concerned with dependency coordination.
class ASTProcessorTest < Minitest::Test
  def test_build_ast_creates_ast_from_valid_ruby_code
    processor = RailsDependencyExplorer::Parsing::ASTProcessor.new(player_code)
    ast = processor.build_ast

    refute_nil ast
    assert_respond_to ast, :type
    assert_respond_to ast, :children
  end

  def test_build_ast_returns_nil_for_invalid_ruby_code
    invalid_code = "class Player def attack end"  # Missing 'end' for class
    processor = RailsDependencyExplorer::Parsing::ASTProcessor.new(invalid_code)
    ast = processor.build_ast

    assert_nil ast
  end

  def test_find_class_nodes_finds_single_class
    processor = RailsDependencyExplorer::Parsing::ASTProcessor.new(player_code)
    ast = processor.build_ast
    class_nodes = processor.find_class_nodes(ast)

    assert_equal 1, class_nodes.length
    assert_equal :class, class_nodes.first.type
  end

  def test_find_class_nodes_finds_multiple_classes_and_modules
    ruby_code = <<~RUBY
      module UserHelpers
        def format_name
          StringUtils.capitalize(name)
        end
      end

      class User
        def initialize
          UserHelpers.format_name
        end
      end
    RUBY

    processor = RailsDependencyExplorer::Parsing::ASTProcessor.new(ruby_code)
    ast = processor.build_ast
    class_nodes = processor.find_class_nodes(ast)

    assert_equal 2, class_nodes.length
    types = class_nodes.map(&:type)
    assert_includes types, :module
    assert_includes types, :class
  end

  def test_find_class_nodes_returns_empty_for_non_node
    processor = RailsDependencyExplorer::Parsing::ASTProcessor.new(player_code)
    class_nodes = processor.find_class_nodes("not a node")

    assert_equal [], class_nodes
  end

  def test_extract_class_name_extracts_simple_class_name
    processor = RailsDependencyExplorer::Parsing::ASTProcessor.new(player_code)
    ast = processor.build_ast
    class_nodes = processor.find_class_nodes(ast)
    class_name = processor.extract_class_name(class_nodes.first)

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

    processor = RailsDependencyExplorer::Parsing::ASTProcessor.new(ruby_code)
    ast = processor.build_ast
    class_nodes = processor.find_class_nodes(ast)
    class_name = processor.extract_class_name(class_nodes.first)

    assert_equal "Validatable", class_name
  end

  def test_extract_class_name_returns_empty_for_invalid_node
    processor = RailsDependencyExplorer::Parsing::ASTProcessor.new(player_code)

    # Create a mock node without proper structure
    mock_node = Object.new
    def mock_node.children
      [nil]
    end

    class_name = processor.extract_class_name(mock_node)
    assert_equal "", class_name
  end

  def test_process_classes_returns_class_info_with_names_and_nodes
    processor = RailsDependencyExplorer::Parsing::ASTProcessor.new(player_code)
    class_info_list = processor.process_classes

    assert_equal 1, class_info_list.length

    class_info = class_info_list.first
    assert_equal "Player", class_info[:name]
    assert_respond_to class_info[:node], :type
    assert_equal :class, class_info[:node].type
  end

  def test_process_classes_handles_multiple_classes
    ruby_code = <<~RUBY
      class Player
        def attack
          Enemy.health -= 10
        end
      end

      module GameUtils
        def self.log(message)
          Logger.info(message)
        end
      end
    RUBY

    processor = RailsDependencyExplorer::Parsing::ASTProcessor.new(ruby_code)
    class_info_list = processor.process_classes

    assert_equal 2, class_info_list.length

    names = class_info_list.map { |info| info[:name] }
    assert_includes names, "Player"
    assert_includes names, "GameUtils"
  end

  def test_process_classes_returns_empty_for_invalid_code
    processor = RailsDependencyExplorer::Parsing::ASTProcessor.new("invalid ruby code {")
    class_info_list = processor.process_classes

    assert_equal [], class_info_list
  end

  def test_process_classes_returns_empty_for_code_without_classes
    ruby_code = <<~RUBY
      def standalone_method
        puts "Hello"
      end
      
      x = 42
    RUBY

    processor = RailsDependencyExplorer::Parsing::ASTProcessor.new(ruby_code)
    class_info_list = processor.process_classes

    assert_equal [], class_info_list
  end

  def test_process_classes_filters_out_empty_class_names
    # This would be an edge case where extract_class_name returns empty
    processor = RailsDependencyExplorer::Parsing::ASTProcessor.new(player_code)

    # Mock extract_class_name to return empty string
    def processor.extract_class_name(node)
      ""
    end

    class_info_list = processor.process_classes
    assert_equal [], class_info_list
  end
end
