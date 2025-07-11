# frozen_string_literal: true

require "test_helper"

class ClassDiscoveryTest < Minitest::Test
  def setup
    @parser = Parser::CurrentRuby
  end

  def test_find_class_nodes_returns_class_nodes
    ruby_code = <<~RUBY
      class User
        def name
          @name
        end
      end
    RUBY
    
    ast = @parser.parse(ruby_code)
    class_nodes = RailsDependencyExplorer::Parsing::ClassDiscovery.find_class_nodes(ast)
    
    assert_equal 1, class_nodes.length
    assert_equal :class, class_nodes.first.type
  end

  def test_find_class_nodes_returns_module_nodes
    ruby_code = <<~RUBY
      module UserHelpers
        def format_name
          # implementation
        end
      end
    RUBY
    
    ast = @parser.parse(ruby_code)
    class_nodes = RailsDependencyExplorer::Parsing::ClassDiscovery.find_class_nodes(ast)
    
    assert_equal 1, class_nodes.length
    assert_equal :module, class_nodes.first.type
  end

  def test_find_class_nodes_returns_nested_classes
    ruby_code = <<~RUBY
      module App
        class User
          def name
            @name
          end
        end
        
        class Post
          def title
            @title
          end
        end
      end
    RUBY
    
    ast = @parser.parse(ruby_code)
    class_nodes = RailsDependencyExplorer::Parsing::ClassDiscovery.find_class_nodes(ast)
    
    assert_equal 3, class_nodes.length # App module + User class + Post class
    types = class_nodes.map(&:type)
    assert_includes types, :module
    assert_equal 2, types.count(:class)
  end

  def test_find_class_nodes_returns_empty_for_no_classes
    ruby_code = <<~RUBY
      def standalone_method
        puts "Hello"
      end
      
      @instance_variable = "value"
    RUBY
    
    ast = @parser.parse(ruby_code)
    class_nodes = RailsDependencyExplorer::Parsing::ClassDiscovery.find_class_nodes(ast)
    
    assert_empty class_nodes
  end

  def test_find_class_nodes_handles_nil_node
    class_nodes = RailsDependencyExplorer::Parsing::ClassDiscovery.find_class_nodes(nil)
    
    assert_empty class_nodes
  end

  def test_find_class_nodes_handles_node_without_type
    node_without_type = Object.new
    class_nodes = RailsDependencyExplorer::Parsing::ClassDiscovery.find_class_nodes(node_without_type)
    
    assert_empty class_nodes
  end

  def test_find_class_nodes_with_namespace_returns_namespaced_info
    ruby_code = <<~RUBY
      module App
        module Models
          class User
            def name
              @name
            end
          end
        end
      end
    RUBY
    
    ast = @parser.parse(ruby_code)
    class_info_list = RailsDependencyExplorer::Parsing::ClassDiscovery.find_class_nodes_with_namespace(ast)
    
    assert_equal 3, class_info_list.length
    
    # Find the User class info
    user_info = class_info_list.find { |info| info[:full_name] == "App::Models::User" }
    refute_nil user_info
    assert_equal :class, user_info[:node].type
    
    # Find the App module info
    app_info = class_info_list.find { |info| info[:full_name] == "App" }
    refute_nil app_info
    assert_equal :module, app_info[:node].type
    
    # Find the Models module info
    models_info = class_info_list.find { |info| info[:full_name] == "App::Models" }
    refute_nil models_info
    assert_equal :module, models_info[:node].type
  end

  def test_find_class_nodes_with_namespace_handles_top_level_classes
    ruby_code = <<~RUBY
      class User
        def name
          @name
        end
      end
      
      class Post
        def title
          @title
        end
      end
    RUBY
    
    ast = @parser.parse(ruby_code)
    class_info_list = RailsDependencyExplorer::Parsing::ClassDiscovery.find_class_nodes_with_namespace(ast)
    
    assert_equal 2, class_info_list.length
    
    user_info = class_info_list.find { |info| info[:full_name] == "User" }
    refute_nil user_info
    assert_equal :class, user_info[:node].type
    
    post_info = class_info_list.find { |info| info[:full_name] == "Post" }
    refute_nil post_info
    assert_equal :class, post_info[:node].type
  end

  def test_find_class_nodes_with_namespace_handles_custom_namespace_stack
    ruby_code = <<~RUBY
      class User
        def name
          @name
        end
      end
    RUBY
    
    ast = @parser.parse(ruby_code)
    class_info_list = RailsDependencyExplorer::Parsing::ClassDiscovery.find_class_nodes_with_namespace(ast, ["Custom", "Namespace"])
    
    assert_equal 1, class_info_list.length
    
    user_info = class_info_list.first
    assert_equal "Custom::Namespace::User", user_info[:full_name]
    assert_equal :class, user_info[:node].type
  end

  def test_find_class_nodes_with_namespace_returns_empty_for_no_classes
    ruby_code = <<~RUBY
      def standalone_method
        puts "Hello"
      end
    RUBY
    
    ast = @parser.parse(ruby_code)
    class_info_list = RailsDependencyExplorer::Parsing::ClassDiscovery.find_class_nodes_with_namespace(ast)
    
    assert_empty class_info_list
  end

  def test_find_class_nodes_with_namespace_handles_nil_node
    class_info_list = RailsDependencyExplorer::Parsing::ClassDiscovery.find_class_nodes_with_namespace(nil)
    
    assert_empty class_info_list
  end

  def test_find_class_nodes_with_namespace_handles_empty_namespace_stack
    ruby_code = <<~RUBY
      class User
        def name
          @name
        end
      end
    RUBY
    
    ast = @parser.parse(ruby_code)
    class_info_list = RailsDependencyExplorer::Parsing::ClassDiscovery.find_class_nodes_with_namespace(ast, [])
    
    assert_equal 1, class_info_list.length
    assert_equal "User", class_info_list.first[:full_name]
  end

  def test_find_class_nodes_with_namespace_handles_complex_nesting
    ruby_code = <<~RUBY
      module Outer
        class OuterClass
          def outer_method
            # implementation
          end
        end
        
        module Inner
          class InnerClass
            def inner_method
              # implementation
            end
          end
          
          module DeepInner
            class DeepClass
              def deep_method
                # implementation
              end
            end
          end
        end
      end
    RUBY
    
    ast = @parser.parse(ruby_code)
    class_info_list = RailsDependencyExplorer::Parsing::ClassDiscovery.find_class_nodes_with_namespace(ast)
    
    expected_names = [
      "Outer",
      "Outer::OuterClass", 
      "Outer::Inner",
      "Outer::Inner::InnerClass",
      "Outer::Inner::DeepInner",
      "Outer::Inner::DeepInner::DeepClass"
    ]
    
    actual_names = class_info_list.map { |info| info[:full_name] }.sort
    assert_equal expected_names.sort, actual_names
  end
end
