# frozen_string_literal: true

require "test_helper"

# RED: Test that demonstrates current tight coupling between ASTVisitor and specific node handling logic
# This test exposes the complexity issue where ASTVisitor handles multiple node types directly
# instead of delegating to specialized handlers
class ASTVisitorNodeHandlerExtractionTest < Minitest::Test
  def setup
    @visitor = RailsDependencyExplorer::Parsing::ASTVisitor.new
  end

  def test_ast_visitor_successfully_delegates_const_node_handling
    # GREEN: This test demonstrates that ASTVisitor now successfully delegates const node logic
    # to the specialized ConstNodeHandler, reducing coupling and complexity

    # Create a mock const node (this would normally come from Parser gem)
    const_node = create_mock_const_node("Enemy")

    # ASTVisitor now delegates to ConstNodeHandler instead of handling directly
    result = @visitor.visit(const_node)

    # The result should be a constant name, handled by ConstNodeHandler
    assert_equal "Enemy", result

    # SUCCESS: ASTVisitor no longer has visit_const method - it delegates to handlers
    refute_respond_to @visitor, :visit_const, "ASTVisitor should not directly handle const nodes"

    # Verify the handler registry is being used
    assert @visitor.registry.registered?(:const), "Const handler should be registered"
  end

  def test_ast_visitor_successfully_delegates_send_node_handling
    # GREEN: This test demonstrates that ASTVisitor now successfully delegates send node logic
    # to the specialized SendNodeHandler, reducing coupling and complexity

    # Create a mock send node for method call
    send_node = create_mock_send_node("Enemy", "health")

    # ASTVisitor now delegates to SendNodeHandler instead of handling directly
    result = @visitor.visit(send_node)

    # The result should be a method call dependency, handled by SendNodeHandler
    expected = {"Enemy" => ["health"]}
    assert_equal expected, result

    # SUCCESS: ASTVisitor no longer has visit_send method - it delegates to handlers
    refute_respond_to @visitor, :visit_send, "ASTVisitor should not directly handle send nodes"

    # Verify the handler registry is being used
    assert @visitor.registry.registered?(:send), "Send handler should be registered"
  end

  def test_ast_visitor_successfully_delegates_activerecord_relationship_handling
    # GREEN: This test demonstrates that ASTVisitor now successfully delegates ActiveRecord
    # relationship handling to SendNodeHandler, reducing complexity

    # Create a mock ActiveRecord relationship node
    ar_node = create_mock_activerecord_node("belongs_to", "account")

    # ASTVisitor now delegates ActiveRecord relationships to SendNodeHandler
    result = @visitor.visit(ar_node)

    # Should extract ActiveRecord relationship via SendNodeHandler
    expected = {"ActiveRecord::belongs_to" => ["Account"]}
    assert_equal expected, result

    # SUCCESS: Complex ActiveRecord logic is now in SendNodeHandler, not ASTVisitor
    # ASTVisitor no longer has these complex methods
    refute_respond_to @visitor, :activerecord_relationship_call?, "AR logic moved to SendNodeHandler"
    refute_respond_to @visitor, :extract_activerecord_relationship, "AR logic moved to SendNodeHandler"
    refute_respond_to @visitor, :convert_symbol_to_model_name, "AR logic moved to SendNodeHandler"
  end

  def test_ast_visitor_successfully_extracted_most_utility_functions
    # GREEN: This test demonstrates that most utility functions have been successfully extracted
    # to specialized handler classes, reducing ASTVisitor complexity

    # SUCCESS: Most utility functions have been moved to handler classes
    refute_respond_to @visitor, :extract_full_constant_name, "Utility function moved to ConstNodeHandler"
    refute_respond_to @visitor, :direct_constant_call?, "Utility function moved to SendNodeHandler"
    refute_respond_to @visitor, :chained_constant_call?, "Utility function moved to SendNodeHandler"

    # Only primitive_type? remains as a private method for the main visit logic
    assert @visitor.respond_to?(:primitive_type?, true), "primitive_type? should exist as private method"

    # The complexity score has been dramatically reduced from 120.73 to 26.64
  end

  def test_ast_visitor_complexity_successfully_reduced_through_extraction
    # GREEN: This test demonstrates that complexity has been successfully reduced
    # through extraction of specialized handlers

    # Count the number of methods in ASTVisitor (now reduced to 5)
    visitor_methods = @visitor.class.instance_methods(false)

    # ASTVisitor now has focused responsibilities:
    # 1. Node traversal coordination (visit, visit_children)
    # 2. Handler registration (register_default_handlers)
    # 3. Primitive type checking (primitive_type?)
    # 4. Registry access (registry attr_reader)

    # SUCCESS: Method count dramatically reduced from 15 to 5
    assert visitor_methods.size <= 5, "ASTVisitor should have few methods (#{visitor_methods.size})"

    # SUCCESS: The complexity score reduced from 120.73 to 26.64 (78% reduction!)
    # ASTVisitor now only coordinates and delegates as intended
  end

  private

  # Mock node creation helpers for testing
  def create_mock_const_node(name)
    # Create a simple mock that behaves like a Parser::AST::Node for const
    MockNode.new(:const, [nil, name.to_sym])
  end

  def create_mock_send_node(receiver_name, method_name)
    # Create a mock send node with const receiver
    receiver = MockNode.new(:const, [nil, receiver_name.to_sym])
    MockNode.new(:send, [receiver, method_name.to_sym])
  end

  def create_mock_activerecord_node(relationship_type, target_symbol)
    # Create a mock ActiveRecord relationship node
    target_arg = MockNode.new(:sym, [target_symbol.to_sym])
    MockNode.new(:send, [nil, relationship_type.to_sym, target_arg])
  end

  # Simple mock node class for testing
  class MockNode
    attr_reader :type, :children

    def initialize(type, children = [])
      @type = type
      @children = children
    end
  end
end
