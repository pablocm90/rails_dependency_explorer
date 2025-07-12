# frozen_string_literal: true

require "test_helper"

# Tests for DependencyExplorer dependency injection functionality.
# Ensures proper use of AnalysisResult factory methods and dependency container integration.
# Part of Phase 2.3 cross-module dependency injection implementation (TDD - Behavioral changes).
class DependencyExplorerDependencyInjectionTest < Minitest::Test
  def setup
    @ruby_code = <<~RUBY
      class TestClass
        def test_method
          Logger.new
          DataValidator.validate
        end
      end
    RUBY
    
    @files = {
      "test_file.rb" => @ruby_code
    }
  end

  def test_dependency_explorer_analyze_code_uses_factory
    # Test that analyze_code uses AnalysisResult.create instead of .new
    explorer = RailsDependencyExplorer::Analysis::DependencyExplorer.new
    
    result = explorer.analyze_code(@ruby_code)
    
    # Should return AnalysisResult instance
    assert_instance_of RailsDependencyExplorer::Analysis::AnalysisResult, result
    
    # Should have parsed the dependencies correctly
    dependencies = result.instance_variable_get(:@dependency_data)
    assert dependencies.key?("TestClass")
  end

  def test_dependency_explorer_analyze_files_uses_factory
    # Test that analyze_files uses AnalysisResult.create instead of .new
    explorer = RailsDependencyExplorer::Analysis::DependencyExplorer.new
    
    result = explorer.analyze_files(@files)
    
    # Should return AnalysisResult instance
    assert_instance_of RailsDependencyExplorer::Analysis::AnalysisResult, result
    
    # Should have parsed the dependencies correctly
    dependencies = result.instance_variable_get(:@dependency_data)
    assert dependencies.key?("TestClass")
  end

  def test_dependency_explorer_with_container_injection
    # Test DependencyExplorer with custom dependency container
    container = RailsDependencyExplorer::Analysis::DependencyContainer.new
    
    # Register mock analyzer in container
    container.register(:statistics_calculator) do |data|
      MockStatisticsCalculator.new
    end
    
    explorer = RailsDependencyExplorer::Analysis::DependencyExplorer.new(container: container)
    result = explorer.analyze_code(@ruby_code)
    
    # Should use analyzer from container
    stats_calculator = result.send(:statistics_calculator)
    assert_instance_of MockStatisticsCalculator, stats_calculator
  end

  def test_dependency_explorer_backward_compatibility
    # Test that old API still works without container parameter
    explorer = RailsDependencyExplorer::Analysis::DependencyExplorer.new
    
    result = explorer.analyze_code(@ruby_code)
    
    # Should create default analyzers
    assert_instance_of RailsDependencyExplorer::Analysis::AnalysisResult, result
    
    # Should have working analysis methods
    assert_respond_to result, :statistics
    assert_respond_to result, :circular_dependencies
  end

  def test_dependency_explorer_factory_method
    # Test factory method for creating DependencyExplorer with container
    container = RailsDependencyExplorer::Analysis::DependencyContainer.new
    
    explorer = RailsDependencyExplorer::Analysis::DependencyExplorer.create(container: container)
    
    # Should be DependencyExplorer instance with container
    assert_instance_of RailsDependencyExplorer::Analysis::DependencyExplorer, explorer
    assert_same container, explorer.instance_variable_get(:@container)
  end

  def test_dependency_explorer_nil_container
    # Test that nil container parameter works like no parameter
    explorer = RailsDependencyExplorer::Analysis::DependencyExplorer.new(container: nil)
    
    result = explorer.analyze_code(@ruby_code)
    
    # Should create default analyzers
    assert_instance_of RailsDependencyExplorer::Analysis::AnalysisResult, result
  end

  private

  # Mock analyzer class for testing
  class MockStatisticsCalculator
    def calculate_statistics
      { mock: true }
    end
  end
end
