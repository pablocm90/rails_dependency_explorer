# frozen_string_literal: true

require "minitest/autorun"
require "json"
require_relative "../test_helper"

class DependencyExplorerTest < Minitest::Test
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

  def test_dependency_explorer_provides_dependency_statistics
    player_code = <<~RUBY
      class Player
        def attack
          Enemy.health -= 10
          Logger.info("Player attacked")
        end

        def defend
          Logger.info("Player defended")
        end
      end
    RUBY

    game_code = <<~RUBY
      class Game
        def start
          Player.new
          Logger.info("Game started")
        end

        def end_game
          Player.reset
          Enemy.cleanup
        end
      end
    RUBY

    files = {
      "player.rb" => player_code,
      "game.rb" => game_code
    }

    result = @explorer.analyze_files(files)
    stats = result.statistics

    expected_stats = {
      total_classes: 2,
      total_dependencies: 3,
      most_used_dependency: "Enemy",
      dependency_counts: {
        "Enemy" => 2,
        "Logger" => 2,
        "Player" => 1
      }
    }

    assert_equal expected_stats, stats
  end

  def test_dependency_explorer_detects_circular_dependencies
    # Create code with circular dependencies
    player_code = <<~RUBY
      class Player
        def attack
          Enemy.take_damage(10)
        end
      end
    RUBY

    enemy_code = <<~RUBY
      class Enemy
        def counter_attack
          Player.take_damage(5)
        end
      end
    RUBY

    game_code = <<~RUBY
      class Game
        def start
          Player.new
          Enemy.spawn
        end
      end
    RUBY

    files = {
      "player.rb" => player_code,
      "enemy.rb" => enemy_code,
      "game.rb" => game_code
    }

    result = @explorer.analyze_files(files)
    circular_deps = result.circular_dependencies

    expected_cycles = [
      ["Player", "Enemy", "Player"]
    ]

    assert_equal expected_cycles, circular_deps
  end

  def test_dependency_explorer_calculates_dependency_depth
    # Create code with multiple dependency levels
    player_code = <<~RUBY
      class Player
        def attack
          Weapon.damage
        end
      end
    RUBY

    weapon_code = <<~RUBY
      class Weapon
        def damage
          Material.hardness
        end
      end
    RUBY

    material_code = <<~RUBY
      class Material
        def hardness
          Config.base_hardness
        end
      end
    RUBY

    config_code = <<~RUBY
      class Config
        def self.base_hardness
          10
        end
      end
    RUBY

    files = {
      "player.rb" => player_code,
      "weapon.rb" => weapon_code,
      "material.rb" => material_code,
      "config.rb" => config_code
    }

    result = @explorer.analyze_files(files)
    depth_analysis = result.dependency_depth

    expected_depth = {
      "Player" => 0,    # Root level (no dependencies on it)
      "Weapon" => 1,    # Depends on Player
      "Material" => 2,  # Depends on Weapon
      "Config" => 3     # Depends on Material
    }

    assert_equal expected_depth, depth_analysis
  end

  def test_dependency_explorer_exports_to_json
    ruby_code = <<~RUBY
      class UserService
        def initialize
          @user_repo = UserRepository.new
          @email_service = EmailService.new
        end

        def create_user(params)
          user = @user_repo.create(params)
          @email_service.send_welcome_email(user)
        end
      end
    RUBY

    result = @explorer.analyze_code(ruby_code)
    json_output = result.to_json

    # Verify it's valid JSON
    parsed = JSON.parse(json_output)

    # Verify it contains expected dependency structure
    assert parsed.key?("dependencies")
    assert parsed.key?("statistics")
    assert parsed["dependencies"].key?("UserService")
    assert_includes parsed["dependencies"]["UserService"], "UserRepository"
    assert_includes parsed["dependencies"]["UserService"], "EmailService"
  end

  def test_dependency_explorer_generates_html_report
    ruby_code = <<~RUBY
      class UserService
        def initialize
          @user_repo = UserRepository.new
          @email_service = EmailService.new
        end
      end
    RUBY

    result = @explorer.analyze_code(ruby_code)
    html_output = result.to_html

    # Should be valid HTML structure
    assert_includes html_output, "<html>"
    assert_includes html_output, "</html>"
    assert_includes html_output, "<head>"
    assert_includes html_output, "<body>"

    # Should include dependency information
    assert_includes html_output, "UserService"
    assert_includes html_output, "UserRepository"
    assert_includes html_output, "EmailService"

    # Should include statistics
    assert_includes html_output, "Dependencies Report"
    assert_includes html_output, "Total Classes"
    assert_includes html_output, "Total Dependencies"
  end

  def test_dependency_explorer_detects_require_relative_dependencies
    # This test reproduces the CLI issue with our own project files
    ruby_code = <<~RUBY
      require_relative "../parsing/dependency_parser"
      require_relative "analysis_result"

      module RailsDependencyExplorer
        module Analysis
          class DependencyExplorer
            def analyze_code(ruby_code)
              dependency_data = parse_ruby_code(ruby_code)
              AnalysisResult.new(dependency_data)
            end

            private

            def parse_ruby_code(ruby_code)
              parser = Parsing::DependencyParser.new(ruby_code)
              parser.parse
            end
          end
        end
      end
    RUBY

    result = @explorer.analyze_code(ruby_code)
    graph = result.to_graph

    # Should detect class instantiations as dependencies
    assert_includes graph[:nodes], "DependencyExplorer"
    assert_includes graph[:nodes], "AnalysisResult"
    assert_includes graph[:nodes], "DependencyParser"

    # Should detect the dependency relationships
    assert_includes graph[:edges], ["DependencyExplorer", "AnalysisResult"]
    assert_includes graph[:edges], ["DependencyExplorer", "DependencyParser"]
  end

  def test_dependency_explorer_handles_code_with_modules_and_requires
    # Test simpler case to isolate the issue
    ruby_code = <<~RUBY
      require_relative "some_file"

      class SimpleClass
        def method
          OtherClass.new
        end
      end
    RUBY

    result = @explorer.analyze_code(ruby_code)
    graph = result.to_graph

    # Should detect the class and its dependency
    assert_includes graph[:nodes], "SimpleClass"
    assert_includes graph[:nodes], "OtherClass"
    assert_includes graph[:edges], ["SimpleClass", "OtherClass"]
  end

  def test_analyze_directory_traverses_subdirectories_recursively
    require "tmpdir"
    require "fileutils"

    Dir.mktmpdir do |temp_dir|
      # Create nested directory structure and files
      dirs = create_nested_directory_structure(temp_dir)
      create_user_file(dirs[:models])
      create_user_validator_file(dirs[:concerns])
      create_email_service_file(dirs[:services])

      # Analyze the entire directory structure
      result = @explorer.analyze_directory(temp_dir)
      graph = result.to_graph

      # Verify recursive analysis results
      assert_recursive_analysis_results(graph)
    end
  end

  private

  def create_nested_directory_structure(temp_dir)
    models_dir = File.join(temp_dir, "models")
    concerns_dir = File.join(models_dir, "concerns")
    services_dir = File.join(temp_dir, "services")
    FileUtils.mkdir_p([models_dir, concerns_dir, services_dir])
    {models: models_dir, concerns: concerns_dir, services: services_dir}
  end

  def create_user_file(models_dir)
    File.write(File.join(models_dir, "user.rb"), <<~RUBY)
      class User
        def validate
          UserValidator.check(self)
        end
      end
    RUBY
  end

  def create_user_validator_file(concerns_dir)
    File.write(File.join(concerns_dir, "user_validator.rb"), <<~RUBY)
      module UserValidator
        def self.check(user)
          Logger.info("Validating user")
        end
      end
    RUBY
  end

  def create_email_service_file(services_dir)
    File.write(File.join(services_dir, "email_service.rb"), <<~RUBY)
      class EmailService
        def send_notification
          Mailer.deliver_now
        end
      end
    RUBY
  end

  def assert_recursive_analysis_results(graph)
    # Should find classes/modules from all subdirectories
    expected_nodes = ["User", "UserValidator", "EmailService", "Logger", "Mailer"]
    expected_nodes.each { |node| assert_includes graph[:nodes], node }

    # Should detect dependencies across subdirectories
    expected_edges = [["User", "UserValidator"], ["UserValidator", "Logger"], ["EmailService", "Mailer"]]
    expected_edges.each { |edge| assert_includes graph[:edges], edge }
  end

  def create_player_file(temp_dir)
    player_file = File.join(temp_dir, "player.rb")
    File.write(player_file, <<~RUBY)
      class Player
        def attack
          Enemy.health -= 10
        end
      end
    RUBY
  end

  def create_game_file(temp_dir)
    game_file = File.join(temp_dir, "game.rb")
    File.write(game_file, <<~RUBY)
      class Game
        def start
          Player.new
          Logger.info("Game started")
        end
      end
    RUBY
  end

  def create_non_ruby_file(temp_dir)
    readme_file = File.join(temp_dir, "README.md")
    File.write(readme_file, "# This is not Ruby code")
  end

  def assert_directory_scan_results(graph)
    expected_nodes = ["Player", "Enemy", "Game", "Logger"]
    expected_edges = [["Player", "Enemy"], ["Game", "Player"], ["Game", "Logger"]]

    assert_equal expected_nodes.sort, graph[:nodes].sort
    assert_equal expected_edges.sort, graph[:edges].sort
  end

  def create_user_model_file(temp_dir)
    user_model = File.join(temp_dir, "user_model.rb")
    File.write(user_model, <<~RUBY)
      class UserModel
        def validate
          Logger.info("Validating user")
        end
      end
    RUBY
  end

  def create_user_controller_file(temp_dir)
    user_controller = File.join(temp_dir, "user_controller.rb")
    File.write(user_controller, <<~RUBY)
      class UserController
        def create
          UserModel.new
        end
      end
    RUBY
  end

  def create_email_service_file_for_pattern_test(temp_dir)
    email_service = File.join(temp_dir, "email_service.rb")
    File.write(email_service, <<~RUBY)
      class EmailService
        def send_email
          Mailer.deliver
        end
      end
    RUBY
  end

  def assert_pattern_filter_results(graph)
    expected_nodes = ["UserModel", "Logger"]
    expected_edges = [["UserModel", "Logger"]]

    assert_equal expected_nodes.sort, graph[:nodes].sort
    assert_equal expected_edges.sort, graph[:edges].sort
  end
end
