# frozen_string_literal: true

require 'test_helper'
require_relative '../../lib/rails_dependency_explorer/analysis/interfaces/analyzer_plugin_interface'
require_relative '../../lib/rails_dependency_explorer/analysis/configuration/analyzer_discovery'

class AnalyzerPluginInterfaceTest < Minitest::Test
  def setup
    @plugin_interface = RailsDependencyExplorer::Analysis::Interfaces::AnalyzerPluginInterface.new
  end

  def test_registers_custom_analyzer_plugin
    # Create a mock custom analyzer class
    custom_analyzer = Class.new do
      include RailsDependencyExplorer::Analysis::Interfaces::AnalyzerInterface
      
      def self.name
        "CustomTestAnalyzer"
      end
      
      def analyze(dependencies)
        { custom_analysis: "test result" }
      end
    end
    
    @plugin_interface.register_plugin(:custom_test_analyzer, custom_analyzer)
    
    registered_plugins = @plugin_interface.registered_plugins
    assert_includes registered_plugins.keys, :custom_test_analyzer
    assert_equal custom_analyzer, registered_plugins[:custom_test_analyzer]
  end

  def test_validates_plugin_implements_analyzer_interface
    # Create a class that doesn't implement AnalyzerInterface
    invalid_analyzer = Class.new do
      def self.name
        "InvalidAnalyzer"
      end
    end
    
    error = assert_raises(ArgumentError) do
      @plugin_interface.register_plugin(:invalid_analyzer, invalid_analyzer)
    end
    
    assert_match(/must implement AnalyzerInterface/, error.message)
  end

  def test_loads_plugin_from_file
    # Create a temporary plugin file
    plugin_content = <<~RUBY
      class TestFileAnalyzer
        include RailsDependencyExplorer::Analysis::Interfaces::AnalyzerInterface
        
        def analyze(dependencies)
          { file_analysis: "loaded from file" }
        end
      end
    RUBY
    
    plugin_file = create_temp_plugin_file(plugin_content)
    
    begin
      @plugin_interface.load_plugin_from_file(plugin_file, :test_file_analyzer)
      
      registered_plugins = @plugin_interface.registered_plugins
      assert_includes registered_plugins.keys, :test_file_analyzer
      
      # Test that the loaded plugin works
      analyzer_instance = registered_plugins[:test_file_analyzer].new
      result = analyzer_instance.analyze({})
      assert_equal({ file_analysis: "loaded from file" }, result)
    ensure
      File.delete(plugin_file) if File.exist?(plugin_file)
    end
  end

  def test_discovers_plugins_in_directory
    plugin_dir = create_temp_plugin_directory
    
    begin
      # Create multiple plugin files
      create_plugin_file(plugin_dir, "plugin_one.rb", "PluginOneAnalyzer", "plugin_one_result")
      create_plugin_file(plugin_dir, "plugin_two.rb", "PluginTwoAnalyzer", "plugin_two_result")
      
      discovered_plugins = @plugin_interface.discover_plugins_in_directory(plugin_dir)
      
      assert_equal 2, discovered_plugins.size
      assert_includes discovered_plugins.keys, :plugin_one_analyzer
      assert_includes discovered_plugins.keys, :plugin_two_analyzer
    ensure
      cleanup_temp_directory(plugin_dir)
    end
  end

  def test_integrates_with_analyzer_discovery
    # Register a custom plugin
    custom_analyzer = Class.new do
      include RailsDependencyExplorer::Analysis::Interfaces::AnalyzerInterface
      
      def self.name
        "IntegrationTestAnalyzer"
      end
      
      def analyze(dependencies)
        { integration_test: "success" }
      end
    end
    
    @plugin_interface.register_plugin(:integration_test_analyzer, custom_analyzer)
    
    # Test that it appears in discovery with plugins enabled
    discovery = RailsDependencyExplorer::Analysis::Configuration::AnalyzerDiscovery.new(
      plugin_interface: @plugin_interface
    )
    
    discovered_analyzers = discovery.discover_analyzers
    assert_includes discovered_analyzers.keys, :integration_test_analyzer
    assert_equal custom_analyzer, discovered_analyzers[:integration_test_analyzer]
  end

  def test_plugin_metadata_extraction
    custom_analyzer = Class.new do
      include RailsDependencyExplorer::Analysis::Interfaces::AnalyzerInterface
      
      def self.name
        "MetadataTestAnalyzer"
      end
      
      def analyze(dependencies)
        { metadata_test: "result" }
      end
    end
    
    @plugin_interface.register_plugin(:metadata_test_analyzer, custom_analyzer)
    
    # Test metadata extraction for plugins
    discovery = RailsDependencyExplorer::Analysis::Configuration::AnalyzerDiscovery.new(
      plugin_interface: @plugin_interface
    )
    
    analyzers_with_metadata = discovery.discover_analyzers_with_metadata
    
    assert_includes analyzers_with_metadata.keys, :metadata_test_analyzer
    plugin_metadata = analyzers_with_metadata[:metadata_test_analyzer][:metadata]
    
    assert_equal :general, plugin_metadata[:category]
    assert_match(/metadata test analyzer/, plugin_metadata[:description])
  end

  def test_unregisters_plugin
    custom_analyzer = Class.new do
      include RailsDependencyExplorer::Analysis::Interfaces::AnalyzerInterface
      
      def self.name
        "UnregisterTestAnalyzer"
      end
      
      def analyze(dependencies)
        { unregister_test: "result" }
      end
    end
    
    @plugin_interface.register_plugin(:unregister_test_analyzer, custom_analyzer)
    assert_includes @plugin_interface.registered_plugins.keys, :unregister_test_analyzer
    
    @plugin_interface.unregister_plugin(:unregister_test_analyzer)
    refute_includes @plugin_interface.registered_plugins.keys, :unregister_test_analyzer
  end

  def test_lists_all_plugins
    # Register multiple plugins
    plugin1 = create_mock_analyzer("Plugin1Analyzer")
    plugin2 = create_mock_analyzer("Plugin2Analyzer")
    
    @plugin_interface.register_plugin(:plugin1_analyzer, plugin1)
    @plugin_interface.register_plugin(:plugin2_analyzer, plugin2)
    
    all_plugins = @plugin_interface.list_plugins
    
    assert_equal 2, all_plugins.size
    assert_includes all_plugins, { key: :plugin1_analyzer, class: plugin1, name: "Plugin1Analyzer" }
    assert_includes all_plugins, { key: :plugin2_analyzer, class: plugin2, name: "Plugin2Analyzer" }
  end

  private

  def create_mock_analyzer(name)
    Class.new do
      include RailsDependencyExplorer::Analysis::Interfaces::AnalyzerInterface
      
      define_singleton_method(:name) { name }
      
      def analyze(dependencies)
        { mock_result: "test" }
      end
    end
  end

  def create_temp_plugin_file(content)
    require 'tempfile'
    temp_file = Tempfile.new(['plugin', '.rb'])
    temp_file.write(content)
    temp_file.close
    temp_file.path
  end

  def create_temp_plugin_directory
    require 'tmpdir'
    Dir.mktmpdir('analyzer_plugins')
  end

  def create_plugin_file(dir, filename, class_name, result_value)
    plugin_content = <<~RUBY
      class #{class_name}
        include RailsDependencyExplorer::Analysis::Interfaces::AnalyzerInterface
        
        def analyze(dependencies)
          { result: "#{result_value}" }
        end
      end
    RUBY
    
    File.write(File.join(dir, filename), plugin_content)
  end

  def cleanup_temp_directory(dir)
    FileUtils.rm_rf(dir) if Dir.exist?(dir)
  end
end
