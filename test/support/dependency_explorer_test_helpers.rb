# frozen_string_literal: true

module DependencyExplorerTestHelpers
  # Provides shared setup for dependency explorer tests
  def setup_dependency_explorer
    @explorer = RailsDependencyExplorer::Analysis::DependencyExplorer.new
  end

  # Common Ruby code templates used across tests
  def player_code
    <<~RUBY
      class Player
        def attack
          Enemy.health -= 10
        end
      end
    RUBY
  end

  def game_code
    <<~RUBY
      class Game
        def start
          Player.new
          Logger.info("Game started")
        end
      end
    RUBY
  end

  def user_code
    <<~RUBY
      class User
        def validate
          UserValidator.check(self)
        end
      end
    RUBY
  end

  def complex_player_code
    <<~RUBY
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
  end

  def user_validator_code
    <<~RUBY
      module UserValidator
        def self.check(user)
          Logger.info("Validating user")
        end
      end
    RUBY
  end

  def email_service_code
    <<~RUBY
      class EmailService
        def send_notification
          Logger.info("Sending email")
        end
      end
    RUBY
  end

  # Common dependency data structures
  def simple_dependency_data
    {"Player" => [{"Enemy" => ["health"]}]}
  end

  def complex_dependency_data
    {
      "Player" => [
        {"Enemy" => ["take_damage", "health"]},
        {"GameState" => ["current"]},
        {"Logger" => ["info"]}
      ]
    }
  end

  def rails_dependency_data
    {
      "User" => [
        {"ApplicationRecord" => [[]]},
        {"ActiveRecord::belongs_to" => ["Account"]},
        {"ActiveRecord::has_many" => ["Post"]}
      ]
    }
  end

  # Common expected results
  def simple_expected_graph
    {
      nodes: ["Player", "Enemy"],
      edges: [["Player", "Enemy"]]
    }
  end

  def complex_expected_graph
    {
      nodes: ["Player", "Enemy", "GameState", "Logger"],
      edges: [["Player", "Enemy"], ["Player", "GameState"], ["Player", "Logger"]]
    }
  end

  def game_player_expected_graph
    {
      nodes: ["Player", "Enemy", "Game", "Logger"],
      edges: [["Player", "Enemy"], ["Game", "Player"], ["Game", "Logger"]]
    }
  end

  # File creation helpers for directory tests
  def create_player_file(directory)
    create_ruby_file(directory, "player.rb", player_code)
  end

  def create_game_file(directory)
    create_ruby_file(directory, "game.rb", game_code)
  end

  def create_user_file(directory)
    create_ruby_file(directory, "user.rb", user_code)
  end

  def create_user_validator_file(directory)
    create_ruby_file(directory, "user_validator.rb", user_validator_code)
  end

  def create_email_service_file(directory)
    create_ruby_file(directory, "email_service.rb", email_service_code)
  end

  # Multi-file test data
  def player_game_files
    {
      "player.rb" => player_code,
      "game.rb" => game_code
    }
  end

  def statistics_test_files
    {
      "player.rb" => <<~RUBY,
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
      "game.rb" => <<~RUBY
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
    }
  end

  def expected_statistics
    {
      total_classes: 2,
      total_dependencies: 3,
      most_used_dependency: "Enemy",
      dependency_counts: {
        "Enemy" => 2,
        "Logger" => 2,
        "Player" => 1
      }
    }
  end
end
