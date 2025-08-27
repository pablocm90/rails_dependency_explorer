# frozen_string_literal: true

require 'test_helper'
require_relative '../../lib/rails_dependency_explorer/analysis/pipeline/analyzer_registry'
require_relative '../../lib/rails_dependency_explorer/analysis/configuration/analyzer_configuration'
require_relative '../../lib/rails_dependency_explorer/analysis/configuration/analyzer_discovery'
require_relative '../../lib/rails_dependency_explorer/analysis/interfaces/analyzer_plugin_interface'
require_relative '../../lib/rails_dependency_explorer/analysis/pipeline/analysis_pipeline'

class AnalyzerRegistryIntegrationTest < Minitest::Test
  def setup
    @registry = RailsDependencyExplorer::Analysis::Pipeline::AnalyzerRegistry.new

    # Register some test analyzers
    register_test_analyzers

    # Create a mock discovery that includes our test analyzers
    @discovery = create_mock_discovery
    @configuration = RailsDependencyExplorer::Analysis::Configuration::AnalyzerConfiguration.new(discovery: @discovery)
  end

  def test_registry_respects_configuration_enabled_analyzers
    # Configure to only enable specific analyzers
    @configuration.disable_all
    @configuration.enable(:test_analyzer_one)
    @configuration.enable(:test_analyzer_two)
    
    # Create registry from configuration
    configured_registry = @registry.create_configured_registry(@configuration)
    
    # Should only have enabled analyzers
    registered_keys = configured_registry.list_registered
    assert_includes registered_keys, :test_analyzer_one
    assert_includes registered_keys, :test_analyzer_two
    refute_includes registered_keys, :test_analyzer_three
  end

  def test_registry_respects_configuration_disabled_analyzers
    # Configure to disable specific analyzers
    @configuration.disable(:test_analyzer_two)
    
    # Create registry from configuration
    configured_registry = @registry.create_configured_registry(@configuration)
    
    # Should have all except disabled ones
    registered_keys = configured_registry.list_registered
    assert_includes registered_keys, :test_analyzer_one
    refute_includes registered_keys, :test_analyzer_two
    assert_includes registered_keys, :test_analyzer_three
  end

  def test_registry_respects_category_based_configuration
    # Configure to only enable dependency analysis category
    @configuration.disable_all
    @configuration.enable_category(:dependency_analysis)
    
    # Create registry from configuration
    configured_registry = @registry.create_configured_registry(@configuration)
    
    # Should only have dependency analysis analyzers
    registered_keys = configured_registry.list_registered
    assert_includes registered_keys, :test_analyzer_one  # dependency_analysis category
    refute_includes registered_keys, :test_analyzer_two  # metrics category
    refute_includes registered_keys, :test_analyzer_three  # rails_analysis category
  end

  def test_pipeline_creation_from_configured_registry
    # Configure to only enable specific analyzers
    @configuration.disable_all
    @configuration.enable(:test_analyzer_one)
    @configuration.enable(:test_analyzer_three)
    
    # Create configured registry
    configured_registry = @registry.create_configured_registry(@configuration)
    
    # Create pipeline from configured registry
    pipeline = RailsDependencyExplorer::Analysis::Pipeline::AnalysisPipeline.from_registry(configured_registry)
    
    # Pipeline should only have configured analyzers
    # We can test this by running the pipeline and checking results
    dependencies = { "TestClass" => ["TestDependency"] }
    result = pipeline.analyze(dependencies)

    # Should have results from enabled analyzers only
    assert result.key?(:test_one_analysis)
    refute result.key?(:test_two_analysis)
    assert result.key?(:test_three_analysis)
  end

  def test_registry_preserves_analyzer_metadata
    # Configure to enable specific analyzers
    @configuration.disable_all
    @configuration.enable(:test_analyzer_one)
    
    # Create configured registry
    configured_registry = @registry.create_configured_registry(@configuration)
    
    # Should preserve metadata
    metadata = configured_registry.get_analyzer_metadata(:test_analyzer_one)
    assert_equal :dependency_analysis, metadata[:category]
    assert_equal "Test analyzer one", metadata[:description]
  end

  def test_registry_integration_with_plugin_interface
    # Create plugin interface and register a plugin
    plugin_interface = RailsDependencyExplorer::Analysis::Interfaces::AnalyzerPluginInterface.new
    
    custom_analyzer = Class.new do
      include RailsDependencyExplorer::Analysis::Interfaces::AnalyzerInterface
      
      def self.name
        "CustomPluginAnalyzer"
      end
      
      def analyze(dependencies)
        { custom_plugin_analysis: "plugin result" }
      end
    end
    
    plugin_interface.register_plugin(:custom_plugin_analyzer, custom_analyzer)

    # Also register the plugin in the main registry for this test
    @registry.register(:custom_plugin_analyzer, custom_analyzer,
                      metadata: { category: :plugin, description: "Custom plugin analyzer" })

    # Create a mock discovery that includes the plugin
    mock_discovery_with_plugin = Object.new

    def mock_discovery_with_plugin.discover_analyzers
      {
        custom_plugin_analyzer: Class.new do
          include RailsDependencyExplorer::Analysis::Interfaces::AnalyzerInterface
          def self.name
            "CustomPluginAnalyzer"
          end
          def analyze(dependencies)
            { custom_plugin_analysis: "plugin result" }
          end
        end
      }
    end

    def mock_discovery_with_plugin.discover_analyzers_with_metadata
      {
        custom_plugin_analyzer: {
          class: discover_analyzers[:custom_plugin_analyzer],
          metadata: { category: :plugin, description: "Custom plugin analyzer" }
        }
      }
    end

    # Create configuration with plugin-aware discovery
    config_with_plugins = RailsDependencyExplorer::Analysis::Configuration::AnalyzerConfiguration.new(discovery: mock_discovery_with_plugin)

    # Configure to only enable the plugin
    config_with_plugins.disable_all
    config_with_plugins.enable(:custom_plugin_analyzer)

    # Create registry from configuration (should include plugin)
    configured_registry = @registry.create_configured_registry(config_with_plugins)
    
    # Should have the plugin analyzer
    registered_keys = configured_registry.list_registered
    assert_includes registered_keys, :custom_plugin_analyzer
    
    # Should be able to create the plugin analyzer
    plugin_analyzer = configured_registry.create_analyzer(:custom_plugin_analyzer)
    result = plugin_analyzer.analyze({})
    assert_equal({ custom_plugin_analysis: "plugin result" }, result)
  end

  def test_registry_handles_unknown_configured_analyzers_gracefully
    # Configure to enable an analyzer that doesn't exist in registry
    @configuration.disable_all
    @configuration.enable(:test_analyzer_one)
    @configuration.enable(:nonexistent_analyzer)  # This doesn't exist in registry
    
    # Should not raise error and should include available analyzers
    configured_registry = @registry.create_configured_registry(@configuration)
    
    registered_keys = configured_registry.list_registered
    assert_includes registered_keys, :test_analyzer_one
    refute_includes registered_keys, :nonexistent_analyzer
  end

  def test_registry_configuration_with_empty_configuration
    # Empty configuration should include all available analyzers
    empty_config = RailsDependencyExplorer::Analysis::Configuration::AnalyzerConfiguration.new(discovery: @discovery)
    
    configured_registry = @registry.create_configured_registry(empty_config)
    
    # Should have all registered analyzers
    original_keys = @registry.list_registered
    configured_keys = configured_registry.list_registered
    
    original_keys.each do |key|
      assert_includes configured_keys, key
    end
  end

  private

  def create_mock_discovery
    # Create a mock discovery that returns our test analyzers
    mock_discovery = Object.new

    def mock_discovery.discover_analyzers
      {
        test_analyzer_one: Class.new do
          include RailsDependencyExplorer::Analysis::Interfaces::AnalyzerInterface
          def analyze(dependencies)
            { test_one_analysis: "result one" }
          end
        end,
        test_analyzer_two: Class.new do
          include RailsDependencyExplorer::Analysis::Interfaces::AnalyzerInterface
          def analyze(dependencies)
            { test_two_analysis: "result two" }
          end
        end,
        test_analyzer_three: Class.new do
          include RailsDependencyExplorer::Analysis::Interfaces::AnalyzerInterface
          def analyze(dependencies)
            { test_three_analysis: "result three" }
          end
        end
      }
    end

    def mock_discovery.discover_analyzers_with_metadata
      {
        test_analyzer_one: {
          class: discover_analyzers[:test_analyzer_one],
          metadata: { category: :dependency_analysis, description: "Test analyzer one" }
        },
        test_analyzer_two: {
          class: discover_analyzers[:test_analyzer_two],
          metadata: { category: :metrics, description: "Test analyzer two" }
        },
        test_analyzer_three: {
          class: discover_analyzers[:test_analyzer_three],
          metadata: { category: :rails_analysis, description: "Test analyzer three" }
        }
      }
    end

    mock_discovery
  end

  def register_test_analyzers
    # Register test analyzers with different categories
    test_analyzer_one = Class.new do
      include RailsDependencyExplorer::Analysis::Interfaces::AnalyzerInterface
      
      def analyze(dependencies)
        { test_one_analysis: "result one" }
      end
    end
    
    test_analyzer_two = Class.new do
      include RailsDependencyExplorer::Analysis::Interfaces::AnalyzerInterface
      
      def analyze(dependencies)
        { test_two_analysis: "result two" }
      end
    end
    
    test_analyzer_three = Class.new do
      include RailsDependencyExplorer::Analysis::Interfaces::AnalyzerInterface
      
      def analyze(dependencies)
        { test_three_analysis: "result three" }
      end
    end
    
    @registry.register(:test_analyzer_one, test_analyzer_one, 
                      metadata: { category: :dependency_analysis, description: "Test analyzer one" })
    @registry.register(:test_analyzer_two, test_analyzer_two, 
                      metadata: { category: :metrics, description: "Test analyzer two" })
    @registry.register(:test_analyzer_three, test_analyzer_three, 
                      metadata: { category: :rails_analysis, description: "Test analyzer three" })
  end
end
