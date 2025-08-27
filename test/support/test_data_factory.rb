# frozen_string_literal: true

module TestDataFactory
  # Factory for creating common dependency data structures used across tests
  # Eliminates duplication identified in RubyCritic analysis (scores 36-67)
  class DependencyDataFactory
    # Simple circular dependency: Player -> Enemy -> Player
    def self.simple_circular_dependency
      {
        "Player" => [{"Enemy" => ["take_damage"]}],
        "Enemy" => [{"Player" => ["take_damage"]}]
      }
    end

    # Acyclic dependency graph: Player -> Enemy, Game -> Player
    def self.acyclic_dependency_graph
      {
        "Player" => [{"Enemy" => ["take_damage"]}],
        "Game" => [{"Player" => ["new"]}]
      }
    end

    # Complex circular dependency: A -> B -> C -> A
    def self.complex_circular_dependency
      {
        "A" => [{"B" => ["method"]}],
        "B" => [{"C" => ["method"]}],
        "C" => [{"A" => ["method"]}]
      }
    end

    # Rails components dependency data
    def self.rails_components_data
      {
        "User" => [{"ApplicationRecord" => [[]]}],
        "UsersController" => [{"ApplicationController" => [[]]}],
        "UserService" => [{"Logger" => ["info"]}]
      }
    end

    # Empty dependency data
    def self.empty_dependency_data
      {}
    end

    # Single class with no dependencies
    def self.standalone_class_data
      {"Standalone" => []}
    end

    # ActiveRecord relationships data
    def self.activerecord_relationships_data
      {
        "User" => [
          {"ApplicationRecord" => [[]]},
          {"ActiveRecord::belongs_to" => ["Account"]},
          {"ActiveRecord::has_many" => ["Post"]}
        ]
      }
    end

    # Complex dependency data with multiple relationships
    def self.complex_dependency_data
      {
        "Player" => [
          {"Enemy" => ["take_damage", "health"]},
          {"GameState" => ["current"]},
          {"Logger" => ["info"]}
        ]
      }
    end

    # Simple dependency for basic tests
    def self.simple_dependency_data
      {"Player" => [{"Enemy" => ["health"]}]}
    end
  end

  # Factory for creating common Ruby code templates used in tests
  # Eliminates code duplication in test file creation
  class RubyCodeFactory
    def self.player_class
      <<~RUBY
        class Player
          def attack
            Enemy.health -= 10
          end
        end
      RUBY
    end

    def self.game_class
      <<~RUBY
        class Game
          def start
            Player.new
            Logger.info("Game started")
          end
        end
      RUBY
    end

    def self.user_class
      <<~RUBY
        class User
          def validate
            UserValidator.check(self)
          end
        end
      RUBY
    end

    def self.complex_player_class
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

    def self.user_validator_module
      <<~RUBY
        module UserValidator
          def self.check(user)
            Logger.info("Validating user")
          end
        end
      RUBY
    end

    def self.email_service_class
      <<~RUBY
        class EmailService
          def send_notification
            Logger.info("Sending email")
          end
        end
      RUBY
    end

    def self.test_class_with_logger
      <<~RUBY
        class TestClass
          def initialize
            @logger = Logger.new
          end
        end
      RUBY
    end

    def self.user_service_class
      <<~RUBY
        class UserService
          def process_user(user)
            UserRepository.save(user)
            Logger.info("User processed")
          end
        end
      RUBY
    end
  end

  # Factory for creating common test assertions and expectations
  # Reduces duplication in test assertion patterns
  class AssertionFactory
    def self.empty_graph_structure
      {
        nodes: [],
        edges: []
      }
    end

    def self.standalone_graph_structure
      {
        nodes: ["Standalone"],
        edges: []
      }
    end

    def self.simple_circular_cycle
      [["Player", "Enemy", "Player"]]
    end

    def self.complex_circular_cycle
      [["A", "B", "C", "A"]]
    end

    def self.no_cycles
      []
    end

    def self.rails_component_categories
      {
        models: ["User"],
        controllers: ["UsersController"],
        services: ["UserService"],
        other: ["Logger"]
      }
    end
  end

  # Factory for creating analyzer instances with common configurations
  # Eliminates repetitive analyzer setup across tests
  class AnalyzerFactory
    def self.create_analysis_result(dependency_data)
      RailsDependencyExplorer::Analysis::Pipeline::AnalysisResult.new(dependency_data)
    end

    def self.create_circular_dependency_analyzer(dependency_data)
      RailsDependencyExplorer::Analysis::Analyzers::CircularDependencyAnalyzer.new(dependency_data)
    end

    def self.create_dependency_collection
      RailsDependencyExplorer::Analysis::Configuration::DependencyCollection.new
    end

    def self.create_dependency_statistics_calculator(dependency_data)
      RailsDependencyExplorer::Analysis::Analyzers::DependencyStatisticsCalculator.new(dependency_data)
    end

    def self.create_dependency_depth_analyzer(dependency_data)
      RailsDependencyExplorer::Analysis::Analyzers::DependencyDepthAnalyzer.new(dependency_data)
    end
  end
end
