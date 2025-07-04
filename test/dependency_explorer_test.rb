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
end
