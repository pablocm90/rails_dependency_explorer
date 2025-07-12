# frozen_string_literal: true

require 'test_helper'
require_relative '../../lib/rails_dependency_explorer/analysis/analyzer_configuration'

class AnalyzerConfigurationTest < Minitest::Test
  def setup
    @config = RailsDependencyExplorer::Analysis::AnalyzerConfiguration.new
  end

  def test_enables_all_analyzers_by_default
    # Should enable all discovered analyzers by default
    enabled = @config.enabled_analyzers
    
    assert_includes enabled, :circular_dependency_analyzer
    assert_includes enabled, :dependency_depth_analyzer
    assert_includes enabled, :dependency_statistics_calculator
    assert_includes enabled, :rails_component_analyzer
    assert_includes enabled, :active_record_relationship_analyzer
  end

  def test_disables_specific_analyzers
    @config.disable(:circular_dependency_analyzer)
    
    enabled = @config.enabled_analyzers
    refute_includes enabled, :circular_dependency_analyzer
    assert_includes enabled, :dependency_depth_analyzer
    assert_includes enabled, :dependency_statistics_calculator
  end

  def test_enables_specific_analyzers
    @config.disable_all
    @config.enable(:circular_dependency_analyzer)
    
    enabled = @config.enabled_analyzers
    assert_includes enabled, :circular_dependency_analyzer
    refute_includes enabled, :dependency_depth_analyzer
    refute_includes enabled, :dependency_statistics_calculator
  end

  def test_filters_analyzers_by_category
    @config.disable_all
    @config.enable_category(:dependency_analysis)
    
    enabled = @config.enabled_analyzers
    assert_includes enabled, :circular_dependency_analyzer  # dependency_analysis
    assert_includes enabled, :dependency_depth_analyzer     # dependency_analysis
    refute_includes enabled, :dependency_statistics_calculator  # metrics
  end

  def test_disables_analyzers_by_category
    @config.disable_category(:metrics)
    
    enabled = @config.enabled_analyzers
    assert_includes enabled, :circular_dependency_analyzer  # dependency_analysis
    refute_includes enabled, :dependency_statistics_calculator  # metrics
  end

  def test_configuration_from_hash
    config_hash = {
      enabled: [:circular_dependency_analyzer, :dependency_depth_analyzer],
      disabled: [:dependency_statistics_calculator]
    }
    
    @config.configure(config_hash)
    enabled = @config.enabled_analyzers
    
    assert_includes enabled, :circular_dependency_analyzer
    assert_includes enabled, :dependency_depth_analyzer
    refute_includes enabled, :dependency_statistics_calculator
  end

  def test_configuration_with_categories
    config_hash = {
      enabled_categories: [:dependency_analysis],
      disabled_categories: [:metrics]
    }
    
    @config.configure(config_hash)
    enabled = @config.enabled_analyzers
    
    assert_includes enabled, :circular_dependency_analyzer  # dependency_analysis
    refute_includes enabled, :dependency_statistics_calculator  # metrics
  end

  def test_analyzer_enabled_check
    @config.disable(:circular_dependency_analyzer)
    
    refute @config.analyzer_enabled?(:circular_dependency_analyzer)
    assert @config.analyzer_enabled?(:dependency_depth_analyzer)
  end

  def test_get_enabled_analyzer_classes
    @config.disable_all
    @config.enable(:circular_dependency_analyzer)
    @config.enable(:dependency_depth_analyzer)
    
    enabled_classes = @config.enabled_analyzer_classes
    
    assert_includes enabled_classes.keys, :circular_dependency_analyzer
    assert_includes enabled_classes.keys, :dependency_depth_analyzer
    refute_includes enabled_classes.keys, :dependency_statistics_calculator
    
    # Should return actual class references
    assert_equal RailsDependencyExplorer::Analysis::CircularDependencyAnalyzer,
                 enabled_classes[:circular_dependency_analyzer]
  end

  def test_reset_configuration
    @config.disable(:circular_dependency_analyzer)
    @config.disable_category(:metrics)
    
    @config.reset
    
    # Should re-enable all analyzers after reset
    enabled = @config.enabled_analyzers
    assert_includes enabled, :circular_dependency_analyzer
    assert_includes enabled, :dependency_statistics_calculator
  end

  def test_configuration_with_unknown_analyzer
    # Should handle unknown analyzers gracefully
    @config.enable(:unknown_analyzer)
    @config.disable(:another_unknown_analyzer)
    
    # Should not crash and should still work with known analyzers
    enabled = @config.enabled_analyzers
    assert_includes enabled, :circular_dependency_analyzer
  end

  def test_configuration_with_unknown_category
    # Should handle unknown categories gracefully
    @config.enable_category(:unknown_category)
    @config.disable_category(:another_unknown_category)
    
    # Should not crash and should still work with known categories
    enabled = @config.enabled_analyzers
    assert_includes enabled, :circular_dependency_analyzer
  end
end
