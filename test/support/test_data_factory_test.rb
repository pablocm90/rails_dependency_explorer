# frozen_string_literal: true

require "test_helper"

# Test to demonstrate the need for centralized test data creation
# This test exposes the current duplication issues in test data
class TestDataFactoryTest < Minitest::Test
  def test_factory_eliminates_duplicate_dependency_data_patterns
    # RED: This test demonstrates that we need centralized test data creation
    # Previously, similar dependency data was duplicated across multiple test files
    
    # Test that factory provides consistent data structures
    circular_data = DependencyDataFactory.simple_circular_dependency
    acyclic_data = DependencyDataFactory.acyclic_dependency_graph
    
    # Verify the factory creates expected structures
    assert_equal 2, circular_data.keys.size
    assert_equal 2, acyclic_data.keys.size
    
    # Verify circular dependency structure
    assert circular_data.key?("Player")
    assert circular_data.key?("Enemy")
    assert_equal [{"Enemy" => ["take_damage"]}], circular_data["Player"]
    assert_equal [{"Player" => ["take_damage"]}], circular_data["Enemy"]
    
    # Verify acyclic dependency structure
    assert acyclic_data.key?("Player")
    assert acyclic_data.key?("Game")
    assert_equal [{"Enemy" => ["take_damage"]}], acyclic_data["Player"]
    assert_equal [{"Player" => ["new"]}], acyclic_data["Game"]
  end

  def test_factory_provides_consistent_ruby_code_templates
    # Test that Ruby code factory eliminates code duplication
    player_code = RubyCodeFactory.player_class
    game_code = RubyCodeFactory.game_class
    
    # Verify code templates are properly formatted
    assert_includes player_code, "class Player"
    assert_includes player_code, "def attack"
    assert_includes player_code, "Enemy.health -= 10"
    
    assert_includes game_code, "class Game"
    assert_includes game_code, "def start"
    assert_includes game_code, "Player.new"
  end

  def test_factory_creates_consistent_analyzer_instances
    # Test that analyzer factory eliminates repetitive setup
    dependency_data = DependencyDataFactory.simple_dependency_data
    
    result = AnalyzerFactory.create_analysis_result(dependency_data)
    analyzer = AnalyzerFactory.create_circular_dependency_analyzer(dependency_data)
    collection = AnalyzerFactory.create_dependency_collection
    
    # Verify instances are created correctly
    assert_instance_of RailsDependencyExplorer::Analysis::Pipeline::AnalysisResult, result
    assert_instance_of RailsDependencyExplorer::Analysis::Analyzers::CircularDependencyAnalyzer, analyzer
    assert_instance_of RailsDependencyExplorer::Analysis::Configuration::DependencyCollection, collection
  end

  def test_factory_provides_consistent_assertion_structures
    # Test that assertion factory eliminates duplicate assertion patterns
    empty_graph = AssertionFactory.empty_graph_structure
    standalone_graph = AssertionFactory.standalone_graph_structure
    
    # Verify assertion structures
    assert_equal({nodes: [], edges: []}, empty_graph)
    assert_equal({nodes: ["Standalone"], edges: []}, standalone_graph)
    
    # Verify cycle expectations
    assert_equal [["Player", "Enemy", "Player"]], AssertionFactory.simple_circular_cycle
    assert_equal [], AssertionFactory.no_cycles
  end

  def test_factory_eliminates_rails_component_data_duplication
    # Test Rails-specific data factory
    rails_data = DependencyDataFactory.rails_components_data
    expected_categories = AssertionFactory.rails_component_categories
    
    # Verify Rails component structure
    assert rails_data.key?("User")
    assert rails_data.key?("UsersController")
    assert rails_data.key?("UserService")
    
    # Verify expected categories structure
    assert_equal ["User"], expected_categories[:models]
    assert_equal ["UsersController"], expected_categories[:controllers]
    assert_equal ["UserService"], expected_categories[:services]
  end

  def test_factory_supports_activerecord_relationship_patterns
    # Test ActiveRecord-specific data patterns
    ar_data = DependencyDataFactory.activerecord_relationships_data
    
    # Verify ActiveRecord relationship structure
    user_dependencies = ar_data["User"]
    assert_includes user_dependencies, {"ApplicationRecord" => [[]]}
    assert_includes user_dependencies, {"ActiveRecord::belongs_to" => ["Account"]}
    assert_includes user_dependencies, {"ActiveRecord::has_many" => ["Post"]}
  end

  def test_factory_handles_complex_dependency_scenarios
    # Test complex dependency patterns
    complex_data = DependencyDataFactory.complex_dependency_data
    
    # Verify complex structure
    player_deps = complex_data["Player"]
    assert_equal 3, player_deps.size
    
    # Check specific dependencies
    assert_includes player_deps, {"Enemy" => ["take_damage", "health"]}
    assert_includes player_deps, {"GameState" => ["current"]}
    assert_includes player_deps, {"Logger" => ["info"]}
  end

  def test_factory_integration_with_existing_test_helpers
    # Test that factory integrates well with existing test helpers
    # This ensures backward compatibility while eliminating duplication
    
    # Use factory data with existing helper methods
    dependency_data = DependencyDataFactory.simple_dependency_data
    result = create_simple_analysis_result  # From existing helper
    
    # Should work together seamlessly
    assert_instance_of RailsDependencyExplorer::Analysis::Pipeline::AnalysisResult, result
    
    # Factory should provide more consistent data than inline creation
    factory_result = AnalyzerFactory.create_analysis_result(dependency_data)
    assert_instance_of RailsDependencyExplorer::Analysis::Pipeline::AnalysisResult, factory_result
  end
end
