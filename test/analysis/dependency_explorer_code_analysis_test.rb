# frozen_string_literal: true

require "minitest/autorun"
require "json"
require_relative "../test_helper"

class DependencyExplorerCodeAnalysisTest < Minitest::Test
  def setup
    @explorer = RailsDependencyExplorer::Analysis::DependencyExplorer.new
  end

  def test_dependency_explorer_integrates_parser_and_visualizer_for_single_class
    ruby_code = <<~RUBY
      class Player
        def attack
          Enemy.health -= 10
        end
      end
    RUBY

    result = @explorer.analyze_code(ruby_code)

    expected_graph = {
      nodes: ["Player", "Enemy"],
      edges: [["Player", "Enemy"]]
    }

    assert_equal expected_graph, result.to_graph
  end

  def test_dependency_explorer_generates_dot_output_from_ruby_code
    ruby_code = <<~RUBY
      class Player
        def attack
          Enemy.health -= 10
        end
      end
    RUBY

    result = @explorer.analyze_code(ruby_code)
    expected_dot = "digraph dependencies {\n  \"Player\" -> \"Enemy\";\n}"

    assert_equal expected_dot, result.to_dot
  end

  def test_dependency_explorer_handles_empty_code_gracefully
    empty_code = ""
    invalid_code = "invalid ruby syntax {"

    # Test empty code
    result = @explorer.analyze_code(empty_code)
    assert_equal({nodes: [], edges: []}, result.to_graph)

    # Test invalid code - should not crash
    result = @explorer.analyze_code(invalid_code)
    assert_equal({nodes: [], edges: []}, result.to_graph)
  end
end
