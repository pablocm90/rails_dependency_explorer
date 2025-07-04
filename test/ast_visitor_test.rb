# frozen_string_literal: true

require "minitest/autorun"
require "parser/current"
require_relative "../lib/rails_dependency_explorer/ast_visitor"

class ASTVisitorTest < Minitest::Test
  def setup
    @visitor = RailsDependencyExplorer::ASTVisitor.new
  end

  def test_visit_returns_empty_array_for_nil_node
    result = @visitor.visit(nil)
    expected = []

    assert_equal expected, result
  end

  def test_visit_returns_empty_array_for_primitive_types
    result_string = @visitor.visit("string")
    result_symbol = @visitor.visit(:symbol)
    result_integer = @visitor.visit(42)

    assert_equal [], result_string
    assert_equal [], result_symbol
    assert_equal [], result_integer
  end

  def test_visit_const_node_calls_visit_const
    # Create a simple const node: Enemy
    parser = Parser::CurrentRuby
    ast = parser.parse("Enemy")

    result = @visitor.visit(ast)
    expected = "Enemy"

    assert_equal expected, result
  end

  def test_visit_send_node_calls_visit_send
    # Create a send node: Enemy.health
    parser = Parser::CurrentRuby
    ast = parser.parse("Enemy.health")

    result = @visitor.visit(ast)
    expected = {"Enemy" => ["health"]}

    assert_equal expected, result
  end

  def test_visit_children_traverses_unknown_node_types
    # Create a more complex AST with multiple nodes
    parser = Parser::CurrentRuby
    ast = parser.parse("x = Enemy.health")

    result = @visitor.visit(ast)
    expected = [{"Enemy" => ["health"]}]

    assert_equal expected, result
  end

  def test_visit_nested_const_node
    # Create a nested const node: Config::MAX_HEALTH
    parser = Parser::CurrentRuby
    ast = parser.parse("Config::MAX_HEALTH")

    result = @visitor.visit(ast)
    expected = {"Config" => ["MAX_HEALTH"]}

    assert_equal expected, result
  end
end
