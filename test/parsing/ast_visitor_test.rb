# frozen_string_literal: true

require "minitest/autorun"
require "parser/current"
require_relative "../test_helper"

class ASTVisitorTest < Minitest::Test
  def setup
    @visitor = RailsDependencyExplorer::Parsing::ASTVisitor.new
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

  def test_registry_allows_custom_handler_registration
    # Register a custom handler for a new node type
    custom_handler = proc { |node| "custom: #{node.type}" }
    @visitor.registry.register(:custom_type, custom_handler)

    # Create a mock node with custom type
    mock_node = Object.new
    def mock_node.type
      :custom_type
    end

    result = @visitor.visit(mock_node)
    expected = "custom: custom_type"

    assert_equal expected, result
  end

  def test_visit_activerecord_belongs_to_relationship
    # Create a send node: belongs_to :account
    parser = Parser::CurrentRuby
    ast = parser.parse("belongs_to :account")

    result = @visitor.visit(ast)
    expected = {"ActiveRecord::belongs_to" => ["Account"]}

    assert_equal expected, result
  end

  def test_visit_activerecord_has_many_relationship
    # Create a send node: has_many :posts
    parser = Parser::CurrentRuby
    ast = parser.parse("has_many :posts")

    result = @visitor.visit(ast)
    expected = {"ActiveRecord::has_many" => ["Post"]}

    assert_equal expected, result
  end

  def test_visit_activerecord_has_one_relationship
    # Create a send node: has_one :profile
    parser = Parser::CurrentRuby
    ast = parser.parse("has_one :profile")

    result = @visitor.visit(ast)
    expected = {"ActiveRecord::has_one" => ["Profile"]}

    assert_equal expected, result
  end

  def test_visit_activerecord_has_and_belongs_to_many_relationship
    # Create a send node: has_and_belongs_to_many :roles
    parser = Parser::CurrentRuby
    ast = parser.parse("has_and_belongs_to_many :roles")

    result = @visitor.visit(ast)
    expected = {"ActiveRecord::has_and_belongs_to_many" => ["Role"]}

    assert_equal expected, result
  end

  def test_visit_non_activerecord_method_call_with_nil_receiver
    # Create a send node: validates :email, presence: true
    parser = Parser::CurrentRuby
    ast = parser.parse("validates :email, presence: true")

    result = @visitor.visit(ast)
    # Should not be treated as ActiveRecord relationship, should traverse children
    expected = []

    assert_equal expected, result
  end

  # Test to ensure behavior remains identical after removing static method duplication
  def test_instance_methods_work_without_static_delegation
    # Test that all instance methods work correctly without delegating to static methods
    parser = Parser::CurrentRuby

    # Test primitive_type? instance method
    assert_equal true, @visitor.send(:primitive_type?, "string")
    assert_equal true, @visitor.send(:primitive_type?, :symbol)
    assert_equal true, @visitor.send(:primitive_type?, 42)

    # Test direct_constant_call? instance method
    const_node = parser.parse("Enemy.health").children[0]
    assert_equal true, @visitor.send(:direct_constant_call?, const_node)

    # Test chained_constant_call? instance method
    chained_node = parser.parse("GameState.current.update")
    send_node = chained_node.children[0] # The GameState.current part
    assert_equal true, @visitor.send(:chained_constant_call?, send_node)

    # Test activerecord_relationship_call? instance method
    ar_node = parser.parse("belongs_to :account")
    assert_equal true, @visitor.send(:activerecord_relationship_call?, nil, ar_node)
  end
end
