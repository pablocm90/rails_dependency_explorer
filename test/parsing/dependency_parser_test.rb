# frozen_string_literal: true

require "minitest/autorun"
require_relative "../test_helper"

class DependencyParserTest < Minitest::Test
  def test_it_parses_the_caller_class
    ruby_code = <<~RUBY
      class Player
         def attack
           Enemy.health -= 10
         end
       end
    RUBY
    expected = {
      "Player" => [{"Enemy" => ["health"]}]
    }
    assert_equal expected, RailsDependencyExplorer::Parsing::DependencyParser.new(ruby_code).parse
  end

  def test_it_parses_multiple_dependencies_with_various_patterns
    ruby_code = <<~RUBY
      class Player
        def complex_attack
          Enemy.take_damage(10)
          Enemy.health -= 5
          GameState.current.update
          max_health = Config::MAX_HEALTH
          Logger.info("Attack completed")
        end
      end
    RUBY

    expected = {
      "Player" => [
        {"Enemy" => ["take_damage", "health"]},
        {"GameState" => ["current"]},
        {"Config" => ["MAX_HEALTH"]},
        {"Logger" => ["info"]}
      ]
    }

    assert_equal expected, RailsDependencyExplorer::Parsing::DependencyParser.new(ruby_code).parse
  end

  def test_it_parses_modules_with_dependencies
    ruby_code = <<~RUBY
      module Validatable
        def self.check(object)
          Logger.info("Validating object")
          ErrorHandler.handle_errors
        end
      end
    RUBY

    expected = {
      "Validatable" => [
        {"Logger" => ["info"]},
        {"ErrorHandler" => ["handle_errors"]}
      ]
    }

    assert_equal expected, RailsDependencyExplorer::Parsing::DependencyParser.new(ruby_code).parse
  end

  def test_it_parses_mixed_classes_and_modules
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

        def validate
          Validator.check(self)
        end
      end
    RUBY

    expected = {
      "UserHelpers" => [{"StringUtils" => ["capitalize"]}],
      "User" => [
        {"UserHelpers" => ["format_name"]},
        {"Validator" => ["check"]}
      ]
    }

    assert_equal expected, RailsDependencyExplorer::Parsing::DependencyParser.new(ruby_code).parse
  end

  # Test to verify separation of concerns after refactoring
  def test_dependency_parser_properly_separates_concerns_after_refactoring
    parser = RailsDependencyExplorer::Parsing::DependencyParser.new(player_code)

    # Main coordination responsibility (should stay)
    assert_respond_to parser, :parse

    # Dependency extraction coordination concerns (should stay)
    assert parser.respond_to?(:extract_dependencies, true)  # private method
    assert parser.respond_to?(:accumulate_visited_dependencies, true)  # private method

    # AST processing is now delegated to ASTProcessor
    assert parser.respond_to?(:ast_processor, true)  # private method
    ast_processor = parser.send(:ast_processor)
    assert_instance_of RailsDependencyExplorer::Parsing::ASTProcessor, ast_processor

    # Static utility methods are now delegated to DependencyParserUtils
    assert_respond_to RailsDependencyExplorer::Parsing::DependencyParser, :extract_class_name
    assert_respond_to RailsDependencyExplorer::Parsing::DependencyParser, :accumulate_visited_dependencies

    # Verify that ASTProcessor can work independently
    independent_processor = RailsDependencyExplorer::Parsing::ASTProcessor.new(player_code)
    class_info_list = independent_processor.process_classes
    assert_equal 1, class_info_list.length
    assert_equal "Player", class_info_list.first[:name]

    # This test verifies that DependencyParser now follows SRP:
    # - DependencyParser: coordinates dependency extraction workflow
    # - ASTProcessor: handles AST building, traversal, and class discovery
    # - DependencyParserUtils: provides static utility methods
    assert true, "DependencyParser now properly separates AST processing from dependency coordination"
  end
end
