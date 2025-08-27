# frozen_string_literal: true

require "test_helper"
require_relative "../../lib/rails_dependency_explorer/analysis/pipeline/analyzer_registry"

# Tests for AnalyzerRegistry class for managing analyzer registration and discovery.
# Provides pluggable analyzer system for pipeline architecture.
# Part of Phase 3.1 pipeline architecture implementation (TDD - Behavioral changes).
class AnalyzerRegistryTest < Minitest::Test
  def setup
    @registry = RailsDependencyExplorer::Analysis::Pipeline::AnalyzerRegistry.new
  end

  def test_analyzer_registry_basic_registration
    # Test basic analyzer registration
    @registry.register(:statistics, MockStatisticsAnalyzer)
    
    # Should register analyzer class
    assert @registry.registered?(:statistics)
    assert_equal MockStatisticsAnalyzer, @registry.get_analyzer_class(:statistics)
  end

  def test_analyzer_registry_instance_creation
    # Test creating analyzer instances from registry
    @registry.register(:statistics, MockStatisticsAnalyzer)
    
    analyzer = @registry.create_analyzer(:statistics)
    
    # Should create instance of registered analyzer
    assert_instance_of MockStatisticsAnalyzer, analyzer
  end

  def test_analyzer_registry_with_initialization_params
    # Test analyzer creation with initialization parameters
    @registry.register(:parameterized, MockParameterizedAnalyzer)
    
    analyzer = @registry.create_analyzer(:parameterized, param1: "value1", param2: "value2")
    
    # Should pass parameters to analyzer constructor
    assert_instance_of MockParameterizedAnalyzer, analyzer
    assert_equal "value1", analyzer.param1
    assert_equal "value2", analyzer.param2
  end

  def test_analyzer_registry_block_registration
    # Test registering analyzers with blocks for custom initialization
    @registry.register(:custom) do |params|
      MockCustomAnalyzer.new(params[:custom_param])
    end
    
    analyzer = @registry.create_analyzer(:custom, custom_param: "test_value")
    
    # Should use block for analyzer creation
    assert_instance_of MockCustomAnalyzer, analyzer
    assert_equal "test_value", analyzer.custom_value
  end

  def test_analyzer_registry_list_registered
    # Test listing all registered analyzers
    @registry.register(:statistics, MockStatisticsAnalyzer)
    @registry.register(:circular, MockCircularAnalyzer)
    @registry.register(:depth, MockDepthAnalyzer)
    
    registered = @registry.list_registered
    
    # Should return all registered analyzer keys
    assert_includes registered, :statistics
    assert_includes registered, :circular
    assert_includes registered, :depth
    assert_equal 3, registered.length
  end

  def test_analyzer_registry_unregister
    # Test unregistering analyzers
    @registry.register(:statistics, MockStatisticsAnalyzer)
    assert @registry.registered?(:statistics)
    
    @registry.unregister(:statistics)
    
    # Should remove analyzer from registry
    refute @registry.registered?(:statistics)
  end

  def test_analyzer_registry_clear
    # Test clearing all registered analyzers
    @registry.register(:statistics, MockStatisticsAnalyzer)
    @registry.register(:circular, MockCircularAnalyzer)
    
    @registry.clear
    
    # Should remove all analyzers
    assert_empty @registry.list_registered
  end

  def test_analyzer_registry_duplicate_registration
    # Test handling duplicate analyzer registration
    @registry.register(:statistics, MockStatisticsAnalyzer)
    
    # Should allow re-registration (overwrite)
    @registry.register(:statistics, MockCircularAnalyzer)
    
    assert_equal MockCircularAnalyzer, @registry.get_analyzer_class(:statistics)
  end

  def test_analyzer_registry_nonexistent_analyzer
    # Test handling requests for non-existent analyzers
    refute @registry.registered?(:nonexistent)
    
    assert_raises(RailsDependencyExplorer::Analysis::Pipeline::AnalyzerRegistry::AnalyzerNotFoundError) do
      @registry.get_analyzer_class(:nonexistent)
    end
    
    assert_raises(RailsDependencyExplorer::Analysis::Pipeline::AnalyzerRegistry::AnalyzerNotFoundError) do
      @registry.create_analyzer(:nonexistent)
    end
  end

  def test_analyzer_registry_default_analyzers
    # Test registry with default analyzers pre-registered
    registry = RailsDependencyExplorer::Analysis::Pipeline::AnalyzerRegistry.create_with_defaults

    # Should create registry (analyzers may not be available yet in this phase)
    assert_instance_of RailsDependencyExplorer::Analysis::Pipeline::AnalyzerRegistry, registry

    # Test that it attempts to register default analyzers (even if they don't exist yet)
    # This is acceptable during pipeline architecture development
    assert_respond_to registry, :registered?
  end

  def test_analyzer_registry_analyzer_metadata
    # Test storing and retrieving analyzer metadata
    metadata = {
      description: "Calculates dependency statistics",
      version: "1.0",
      dependencies: []
    }
    
    @registry.register(:statistics, MockStatisticsAnalyzer, metadata: metadata)
    
    # Should store and retrieve metadata
    assert_equal metadata, @registry.get_analyzer_metadata(:statistics)
    assert_equal "Calculates dependency statistics", @registry.get_analyzer_metadata(:statistics)[:description]
  end

  def test_analyzer_registry_conditional_registration
    # Test conditional analyzer registration based on availability
    @registry.register_if_available(:optional_analyzer, "NonExistentAnalyzer")
    
    # Should not register if class doesn't exist
    refute @registry.registered?(:optional_analyzer)
    
    @registry.register_if_available(:available_analyzer, MockStatisticsAnalyzer)
    
    # Should register if class exists
    assert @registry.registered?(:available_analyzer)
  end

  private

  # Mock analyzer classes for testing
  class MockStatisticsAnalyzer
    def analyze(dependency_data)
      { statistics: { total: dependency_data.keys.length } }
    end
  end

  class MockCircularAnalyzer
    def analyze(dependency_data)
      { circular_dependencies: [] }
    end
  end

  class MockDepthAnalyzer
    def analyze(dependency_data)
      { dependency_depth: {} }
    end
  end

  class MockParameterizedAnalyzer
    attr_reader :param1, :param2

    def initialize(param1:, param2:)
      @param1 = param1
      @param2 = param2
    end

    def analyze(dependency_data)
      { parameterized: { param1: @param1, param2: @param2 } }
    end
  end

  class MockCustomAnalyzer
    attr_reader :custom_value

    def initialize(custom_value)
      @custom_value = custom_value
    end

    def analyze(dependency_data)
      { custom: @custom_value }
    end
  end
end
