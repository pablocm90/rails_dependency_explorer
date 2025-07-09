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
end
