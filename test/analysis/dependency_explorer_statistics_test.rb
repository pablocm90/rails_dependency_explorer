# frozen_string_literal: true

require "minitest/autorun"
require "json"
require_relative "../test_helper"

class DependencyExplorerStatisticsTest < Minitest::Test
  def setup
    setup_dependency_explorer
  end

  def test_dependency_explorer_provides_dependency_statistics
    result = @explorer.analyze_files(statistics_test_files)
    stats = result.statistics
    assert_equal expected_statistics, stats
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
end
