# frozen_string_literal: true

require "minitest/autorun"
require "json"
require_relative "../test_helper"

class DependencyExplorerFileAnalysisTest < Minitest::Test
  def setup
    setup_dependency_explorer
  end

  def test_dependency_explorer_analyzes_multiple_files
    result = @explorer.analyze_files(player_game_files)
    assert_equal game_player_expected_graph, result.to_graph
  end

  def test_dependency_explorer_scans_directory_for_ruby_files
    # Create a temporary directory with Ruby files
    require "tmpdir"
    require "fileutils"

    Dir.mktmpdir do |temp_dir|
      # Create test files
      create_player_file(temp_dir)
      create_game_file(temp_dir)
      create_non_ruby_file(temp_dir)

      result = @explorer.analyze_directory(temp_dir)
      actual_graph = result.to_graph

      assert_directory_scan_results(actual_graph)
    end
  end

  def test_dependency_explorer_filters_files_by_pattern
    # Create a temporary directory with Ruby files
    require "tmpdir"
    require "fileutils"

    Dir.mktmpdir do |temp_dir|
      # Create test files
      create_user_model_file(temp_dir)
      create_user_controller_file(temp_dir)
      create_email_service_file_for_pattern_test(temp_dir)

      # Test filtering for only model files
      result = @explorer.analyze_directory(temp_dir, pattern: "*_model.rb")
      actual_graph = result.to_graph

      assert_pattern_filter_results(actual_graph)
    end
  end

  private

  def create_player_file(temp_dir)
    File.write(File.join(temp_dir, "player.rb"), <<~RUBY)
      class Player
        def attack
          Enemy.health -= 10
        end
      end
    RUBY
  end

  def create_game_file(temp_dir)
    File.write(File.join(temp_dir, "game.rb"), <<~RUBY)
      class Game
        def start
          Player.new
        end
      end
    RUBY
  end

  def create_non_ruby_file(temp_dir)
    File.write(File.join(temp_dir, "readme.txt"), "This is not a Ruby file")
  end

  def create_user_model_file(temp_dir)
    File.write(File.join(temp_dir, "user_model.rb"), <<~RUBY)
      class UserModel
        def save
          Database.insert(self)
        end
      end
    RUBY
  end

  def create_user_controller_file(temp_dir)
    File.write(File.join(temp_dir, "user_controller.rb"), <<~RUBY)
      class UserController
        def create
          UserModel.new
        end
      end
    RUBY
  end

  def create_email_service_file_for_pattern_test(temp_dir)
    File.write(File.join(temp_dir, "email_service.rb"), <<~RUBY)
      class EmailService
        def send_email
          Logger.info("Email sent")
        end
      end
    RUBY
  end

  def assert_directory_scan_results(actual_graph)
    expected_nodes = ["Player", "Enemy", "Game"]
    expected_edges = [["Player", "Enemy"], ["Game", "Player"]]

    assert_equal expected_nodes.sort, actual_graph[:nodes].sort
    assert_equal expected_edges.sort, actual_graph[:edges].sort
  end

  def assert_pattern_filter_results(actual_graph)
    # Should only include UserModel and its dependencies
    expected_nodes = ["UserModel", "Database"]
    expected_edges = [["UserModel", "Database"]]

    assert_equal expected_nodes.sort, actual_graph[:nodes].sort
    assert_equal expected_edges.sort, actual_graph[:edges].sort
  end
end
