# frozen_string_literal: true

require "minitest/autorun"
require_relative "../lib/rails_dependency_explorer/dependency_explorer"

class DependencyExplorerTest < Minitest::Test
  def setup
    @explorer = RailsDependencyExplorer::DependencyExplorer.new
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
    result_empty = @explorer.analyze_code(empty_code)
    expected_empty_graph = {nodes: [], edges: []}
    assert_equal expected_empty_graph, result_empty.to_graph

    # Test invalid code
    result_invalid = @explorer.analyze_code(invalid_code)
    expected_invalid_graph = {nodes: [], edges: []}
    assert_equal expected_invalid_graph, result_invalid.to_graph
  end

  def test_dependency_explorer_analyzes_multiple_files
    player_code = <<~RUBY
      class Player
        def attack
          Enemy.health -= 10
        end
      end
    RUBY

    game_code = <<~RUBY
      class Game
        def start
          Player.new
          Logger.info("Game started")
        end
      end
    RUBY

    files = {
      "player.rb" => player_code,
      "game.rb" => game_code
    }

    result = @explorer.analyze_files(files)

    expected_graph = {
      nodes: ["Player", "Enemy", "Game", "Logger"],
      edges: [["Player", "Enemy"], ["Game", "Player"], ["Game", "Logger"]]
    }

    assert_equal expected_graph, result.to_graph
  end
end
