# frozen_string_literal: true

require "test_helper"

class ContentFilterTest < Minitest::Test
  def setup
    @parser = Parser::CurrentRuby
  end

  def test_has_meaningful_content_returns_true_for_class_with_method_definitions
    ruby_code = <<~RUBY
      class User
        def name
          @name
        end
        
        def self.find(id)
          # implementation
        end
      end
    RUBY
    
    ast = @parser.parse(ruby_code)
    class_node = find_class_node(ast, :User)
    
    assert RailsDependencyExplorer::Parsing::ContentFilter.has_meaningful_content?(class_node)
  end

  def test_has_meaningful_content_returns_true_for_class_with_method_calls
    ruby_code = <<~RUBY
      class User
        has_many :posts
        validates :email, presence: true
        belongs_to :account
      end
    RUBY
    
    ast = @parser.parse(ruby_code)
    class_node = find_class_node(ast, :User)
    
    assert RailsDependencyExplorer::Parsing::ContentFilter.has_meaningful_content?(class_node)
  end

  def test_has_meaningful_content_returns_true_for_module_with_method_definitions
    ruby_code = <<~RUBY
      module Validatable
        def validate
          # implementation
        end
        
        def self.included(base)
          # implementation
        end
      end
    RUBY
    
    ast = @parser.parse(ruby_code)
    module_node = find_module_node(ast, :Validatable)
    
    assert RailsDependencyExplorer::Parsing::ContentFilter.has_meaningful_content?(module_node)
  end

  def test_has_meaningful_content_returns_true_for_module_with_method_calls
    ruby_code = <<~RUBY
      module UserHelpers
        extend ActiveSupport::Concern
        included do
          validates :name, presence: true
        end
      end
    RUBY
    
    ast = @parser.parse(ruby_code)
    module_node = find_module_node(ast, :UserHelpers)
    
    assert RailsDependencyExplorer::Parsing::ContentFilter.has_meaningful_content?(module_node)
  end

  def test_has_meaningful_content_returns_false_for_empty_class
    ruby_code = <<~RUBY
      class EmptyClass
      end
    RUBY
    
    ast = @parser.parse(ruby_code)
    class_node = find_class_node(ast, :EmptyClass)
    
    refute RailsDependencyExplorer::Parsing::ContentFilter.has_meaningful_content?(class_node)
  end

  def test_has_meaningful_content_returns_false_for_empty_module
    ruby_code = <<~RUBY
      module EmptyModule
      end
    RUBY
    
    ast = @parser.parse(ruby_code)
    module_node = find_module_node(ast, :EmptyModule)
    
    refute RailsDependencyExplorer::Parsing::ContentFilter.has_meaningful_content?(module_node)
  end

  def test_has_meaningful_content_returns_false_for_class_with_only_comments
    ruby_code = <<~RUBY
      class CommentOnlyClass
        # This is just a comment
        # Another comment
      end
    RUBY
    
    ast = @parser.parse(ruby_code)
    class_node = find_class_node(ast, :CommentOnlyClass)
    
    refute RailsDependencyExplorer::Parsing::ContentFilter.has_meaningful_content?(class_node)
  end

  def test_has_meaningful_content_handles_nil_node
    refute RailsDependencyExplorer::Parsing::ContentFilter.has_meaningful_content?(nil)
  end

  def test_has_meaningful_content_handles_node_without_children
    # Create a simple node without children
    leaf_node = Parser::AST::Node.new(:sym, [])
    
    refute RailsDependencyExplorer::Parsing::ContentFilter.has_meaningful_content?(leaf_node)
  end

  def test_has_meaningful_definitions_returns_true_for_method_definition
    ruby_code = <<~RUBY
      class User
        def name
          @name
        end
      end
    RUBY
    
    ast = @parser.parse(ruby_code)
    method_node = find_method_node(ast, :name)
    
    assert RailsDependencyExplorer::Parsing::ContentFilter.has_meaningful_definitions?(method_node)
  end

  def test_has_meaningful_definitions_returns_true_for_class_method_definition
    ruby_code = <<~RUBY
      class User
        def self.find(id)
          # implementation
        end
      end
    RUBY
    
    ast = @parser.parse(ruby_code)
    class_method_node = find_class_method_node(ast, :find)
    
    assert RailsDependencyExplorer::Parsing::ContentFilter.has_meaningful_definitions?(class_method_node)
  end

  def test_has_meaningful_definitions_returns_true_for_method_call
    ruby_code = <<~RUBY
      class User
        has_many :posts
      end
    RUBY
    
    ast = @parser.parse(ruby_code)
    send_node = find_send_node(ast, :has_many)
    
    assert RailsDependencyExplorer::Parsing::ContentFilter.has_meaningful_definitions?(send_node)
  end

  def test_has_meaningful_definitions_returns_true_for_begin_block_with_methods
    ruby_code = <<~RUBY
      class User
        def name
          @name
        end
        
        def email
          @email
        end
      end
    RUBY
    
    ast = @parser.parse(ruby_code)
    class_node = find_class_node(ast, :User)
    begin_node = class_node.children[2] # Body of the class
    
    assert RailsDependencyExplorer::Parsing::ContentFilter.has_meaningful_definitions?(begin_node)
  end

  def test_has_meaningful_definitions_returns_false_for_other_node_types
    ruby_code = <<~RUBY
      class User
        @instance_variable = "value"
      end
    RUBY
    
    ast = @parser.parse(ruby_code)
    ivar_node = find_ivar_node(ast)
    
    refute RailsDependencyExplorer::Parsing::ContentFilter.has_meaningful_definitions?(ivar_node)
  end

  def test_has_meaningful_definitions_handles_nil_node
    refute RailsDependencyExplorer::Parsing::ContentFilter.has_meaningful_definitions?(nil)
  end

  def test_has_meaningful_definitions_handles_node_without_type
    node_without_type = Object.new
    
    refute RailsDependencyExplorer::Parsing::ContentFilter.has_meaningful_definitions?(node_without_type)
  end

  private

  def find_class_node(node, class_name)
    return node if node.type == :class && node.children.first.children[1] == class_name
    
    if node.respond_to?(:children) && node.children
      node.children.each do |child|
        next unless child.respond_to?(:type)
        result = find_class_node(child, class_name)
        return result if result
      end
    end
    
    nil
  end

  def find_module_node(node, module_name)
    return node if node.type == :module && node.children.first.children[1] == module_name
    
    if node.respond_to?(:children) && node.children
      node.children.each do |child|
        next unless child.respond_to?(:type)
        result = find_module_node(child, module_name)
        return result if result
      end
    end
    
    nil
  end

  def find_method_node(node, method_name)
    return node if node.type == :def && node.children.first == method_name
    
    if node.respond_to?(:children) && node.children
      node.children.each do |child|
        next unless child.respond_to?(:type)
        result = find_method_node(child, method_name)
        return result if result
      end
    end
    
    nil
  end

  def find_class_method_node(node, method_name)
    return node if node.type == :defs && node.children[1] == method_name
    
    if node.respond_to?(:children) && node.children
      node.children.each do |child|
        next unless child.respond_to?(:type)
        result = find_class_method_node(child, method_name)
        return result if result
      end
    end
    
    nil
  end

  def find_send_node(node, method_name)
    return node if node.type == :send && node.children[1] == method_name
    
    if node.respond_to?(:children) && node.children
      node.children.each do |child|
        next unless child.respond_to?(:type)
        result = find_send_node(child, method_name)
        return result if result
      end
    end
    
    nil
  end

  def find_ivar_node(node)
    return node if node.type == :ivasgn
    
    if node.respond_to?(:children) && node.children
      node.children.each do |child|
        next unless child.respond_to?(:type)
        result = find_ivar_node(child)
        return result if result
      end
    end
    
    nil
  end
end
