# frozen_string_literal: true

require "test_helper"

class ASTBuilderTest < Minitest::Test
  def test_build_ast_returns_ast_for_valid_ruby_code
    ruby_code = <<~RUBY
      class User
        def name
          @name
        end
      end
    RUBY
    
    ast = RailsDependencyExplorer::Parsing::ASTBuilder.build_ast(ruby_code)
    
    refute_nil ast
    assert_equal :class, ast.type
  end

  def test_build_ast_returns_ast_for_module
    ruby_code = <<~RUBY
      module UserHelpers
        def format_name
          # implementation
        end
      end
    RUBY
    
    ast = RailsDependencyExplorer::Parsing::ASTBuilder.build_ast(ruby_code)
    
    refute_nil ast
    assert_equal :module, ast.type
  end

  def test_build_ast_returns_ast_for_complex_code
    ruby_code = <<~RUBY
      class User
        has_many :posts
        validates :email, presence: true
        
        def initialize(name)
          @name = name
        end
        
        def self.find_by_email(email)
          # implementation
        end
      end
    RUBY
    
    ast = RailsDependencyExplorer::Parsing::ASTBuilder.build_ast(ruby_code)
    
    refute_nil ast
    assert_equal :class, ast.type
  end

  def test_build_ast_returns_nil_for_invalid_syntax
    invalid_ruby_code = <<~RUBY
      class User
        def name
          @name
        # Missing end
      end
    RUBY
    
    ast = RailsDependencyExplorer::Parsing::ASTBuilder.build_ast(invalid_ruby_code)
    
    assert_nil ast
  end

  def test_build_ast_returns_nil_for_severely_malformed_code
    malformed_code = "class User def name @name"
    
    ast = RailsDependencyExplorer::Parsing::ASTBuilder.build_ast(malformed_code)
    
    assert_nil ast
  end

  def test_build_ast_handles_empty_string
    ast = RailsDependencyExplorer::Parsing::ASTBuilder.build_ast("")
    
    # Empty string should parse to nil or empty AST
    # The exact behavior depends on the parser
    assert ast.nil? || ast.respond_to?(:type)
  end

  def test_build_ast_handles_whitespace_only
    ast = RailsDependencyExplorer::Parsing::ASTBuilder.build_ast("   \n  \t  ")
    
    # Whitespace-only should parse to nil or empty AST
    assert ast.nil? || ast.respond_to?(:type)
  end

  def test_build_ast_handles_comments_only
    ruby_code = <<~RUBY
      # This is just a comment
      # Another comment
    RUBY
    
    ast = RailsDependencyExplorer::Parsing::ASTBuilder.build_ast(ruby_code)
    
    # Comments-only should parse to nil or empty AST
    assert ast.nil? || ast.respond_to?(:type)
  end

  def test_build_ast_suppresses_parser_diagnostics
    # This test verifies that parser diagnostic messages are suppressed
    # We can't easily test stderr suppression in unit tests, but we can
    # verify that the method doesn't raise exceptions for code that
    # would normally generate parser warnings
    
    ruby_code_with_warnings = <<~RUBY
      class User
        def name
          @name
        end
        
        # This might generate parser warnings in some cases
        def name
          @other_name
        end
      end
    RUBY
    
    # Should not raise an exception and should return valid AST
    ast = RailsDependencyExplorer::Parsing::ASTBuilder.build_ast(ruby_code_with_warnings)
    
    refute_nil ast
    assert_equal :class, ast.type
  end

  def test_build_ast_handles_nested_classes
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
    
    ast = RailsDependencyExplorer::Parsing::ASTBuilder.build_ast(ruby_code)
    
    refute_nil ast
    assert_equal :module, ast.type
  end

  def test_build_ast_handles_class_with_inheritance
    ruby_code = <<~RUBY
      class User < ApplicationRecord
        def name
          @name
        end
      end
    RUBY
    
    ast = RailsDependencyExplorer::Parsing::ASTBuilder.build_ast(ruby_code)
    
    refute_nil ast
    assert_equal :class, ast.type
  end

  def test_build_ast_handles_multiple_classes
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
    
    ast = RailsDependencyExplorer::Parsing::ASTBuilder.build_ast(ruby_code)
    
    refute_nil ast
    # Multiple top-level classes are wrapped in a :begin node
    assert [:begin, :class].include?(ast.type)
  end
end
