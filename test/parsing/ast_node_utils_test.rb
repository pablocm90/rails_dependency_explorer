# frozen_string_literal: true

require "test_helper"

class ASTNodeUtilsTest < Minitest::Test
  def setup
    @ruby_code = <<~RUBY
      module App
        class User
          def name
            "test"
          end
        end
      end
    RUBY
    
    @parser = Parser::CurrentRuby
    @ast = @parser.parse(@ruby_code)
  end

  def test_extract_class_name_from_simple_class
    # Find the User class node
    user_class_node = find_class_node(@ast, :User)
    
    name = RailsDependencyExplorer::Parsing::ASTNodeUtils.extract_class_name(user_class_node)
    assert_equal "User", name
  end

  def test_extract_class_name_returns_empty_for_invalid_node
    invalid_node = @ast.children.first.children.last # body node, not class node
    
    name = RailsDependencyExplorer::Parsing::ASTNodeUtils.extract_class_name(invalid_node)
    assert_equal "", name
  end

  def test_has_children_returns_true_for_nodes_with_children
    assert RailsDependencyExplorer::Parsing::ASTNodeUtils.has_children?(@ast)
  end

  def test_has_children_returns_false_for_nodes_without_children
    leaf_node = create_leaf_node
    refute RailsDependencyExplorer::Parsing::ASTNodeUtils.has_children?(leaf_node)
  end

  def test_has_children_returns_false_for_nil
    refute RailsDependencyExplorer::Parsing::ASTNodeUtils.has_children?(nil)
  end

  def test_traverse_children_yields_each_child
    children_found = []
    
    RailsDependencyExplorer::Parsing::ASTNodeUtils.traverse_children(@ast) do |child|
      children_found << child
    end
    
    assert_equal @ast.children.length, children_found.length
    assert_equal @ast.children, children_found
  end

  def test_traverse_children_handles_node_without_children
    leaf_node = create_leaf_node
    children_found = []
    
    RailsDependencyExplorer::Parsing::ASTNodeUtils.traverse_children(leaf_node) do |child|
      children_found << child
    end
    
    assert_empty children_found
  end

  def test_traverse_children_handles_nil_node
    children_found = []
    
    RailsDependencyExplorer::Parsing::ASTNodeUtils.traverse_children(nil) do |child|
      children_found << child
    end
    
    assert_empty children_found
  end

  def test_is_class_or_module_node_returns_true_for_class
    user_class_node = find_class_node(@ast, :User)
    assert RailsDependencyExplorer::Parsing::ASTNodeUtils.class_or_module_node?(user_class_node)
  end

  def test_is_class_or_module_node_returns_true_for_module
    app_module_node = find_module_node(@ast, :App)
    assert RailsDependencyExplorer::Parsing::ASTNodeUtils.class_or_module_node?(app_module_node)
  end

  def test_is_class_or_module_node_returns_false_for_other_nodes
    method_node = find_method_node(@ast, :name)
    refute RailsDependencyExplorer::Parsing::ASTNodeUtils.class_or_module_node?(method_node)
  end

  private

  def find_class_node(node, class_name)
    return nil unless node&.respond_to?(:type)
    return node if node.type == :class && node.children.first.children[1] == class_name

    if node.respond_to?(:children) && node.children
      node.children.each do |child|
        result = find_class_node(child, class_name)
        return result if result
      end
    end

    nil
  end

  def find_module_node(node, module_name)
    return nil unless node&.respond_to?(:type)
    return node if node.type == :module && node.children.first.children[1] == module_name

    if node.respond_to?(:children) && node.children
      node.children.each do |child|
        result = find_module_node(child, module_name)
        return result if result
      end
    end

    nil
  end

  def find_method_node(node, method_name)
    return nil unless node&.respond_to?(:type)
    return node if node.type == :def && node.children.first == method_name

    if node.respond_to?(:children) && node.children
      node.children.each do |child|
        result = find_method_node(child, method_name)
        return result if result
      end
    end

    nil
  end

  def create_leaf_node
    # Create a simple symbol node that has no children
    Parser::AST::Node.new(:sym, [])
  end
end
