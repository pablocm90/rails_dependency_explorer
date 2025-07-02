# frozen_string_literal: true

require "minitest/autorun"
require_relative "../lib/rails_dependency_explorer/dependency_parser"

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
      "Player" => ["Enemy"]
    }
    assert_equal expected, RailsDependencyExplorer::DependencyParser.new(ruby_code).parse
  end
end
