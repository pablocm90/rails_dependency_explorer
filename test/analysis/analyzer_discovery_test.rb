# frozen_string_literal: true

require 'test_helper'
require_relative '../../lib/rails_dependency_explorer/analysis/analyzer_discovery'

class AnalyzerDiscoveryTest < Minitest::Test
  def setup
    @discovery = RailsDependencyExplorer::Analysis::AnalyzerDiscovery.new
  end

  def test_discovers_analyzer_classes_implementing_interface
    # Should discover all classes that include AnalyzerInterface
    discovered = @discovery.discover_analyzers
    
    # Should find existing analyzer classes
    assert_includes discovered.keys, :circular_dependency_analyzer
    assert_includes discovered.keys, :dependency_depth_analyzer
    assert_includes discovered.keys, :rails_component_analyzer
    
    # Should return class references
    assert_equal RailsDependencyExplorer::Analysis::CircularDependencyAnalyzer, 
                 discovered[:circular_dependency_analyzer]
  end

  def test_discovers_analyzers_with_metadata
    discovered = @discovery.discover_analyzers_with_metadata
    
    # Should include metadata for each discovered analyzer
    circular_analyzer = discovered[:circular_dependency_analyzer]
    refute_nil circular_analyzer[:class]
    refute_nil circular_analyzer[:metadata]
    assert_includes circular_analyzer[:metadata][:description], "circular"
  end

  def test_filters_analyzers_by_category
    discovered = @discovery.discover_analyzers(category: :dependency_analysis)
    
    # Should only return analyzers in the specified category
    assert_includes discovered.keys, :circular_dependency_analyzer
    assert_includes discovered.keys, :dependency_depth_analyzer
  end

  def test_discovers_statistics_analyzer
    discovered = @discovery.discover_analyzers

    # Should find statistics analyzer
    assert_includes discovered.keys, :dependency_statistics_calculator
    assert_equal RailsDependencyExplorer::Analysis::DependencyStatisticsCalculator,
                 discovered[:dependency_statistics_calculator]
  end

  def test_discovers_activerecord_relationship_analyzer
    discovered = @discovery.discover_analyzers
    
    # Should find ActiveRecord relationship analyzer
    assert_includes discovered.keys, :active_record_relationship_analyzer
    assert_equal RailsDependencyExplorer::Analysis::ActiveRecordRelationshipAnalyzer,
                 discovered[:active_record_relationship_analyzer]
  end

  def test_excludes_non_analyzer_classes
    discovered = @discovery.discover_analyzers
    
    # Should not include classes that don't implement AnalyzerInterface
    refute_includes discovered.keys, :analysis_result
    refute_includes discovered.keys, :analyzer_registry
    refute_includes discovered.keys, :analysis_pipeline
  end

  def test_returns_empty_hash_when_no_analyzers_found
    # Create discovery instance that looks in empty namespace
    empty_discovery = RailsDependencyExplorer::Analysis::AnalyzerDiscovery.new(namespace: "NonExistent")
    
    discovered = empty_discovery.discover_analyzers
    assert_empty discovered
  end

  def test_discover_analyzers_with_metadata_includes_all_required_fields
    discovered = @discovery.discover_analyzers_with_metadata
    
    discovered.each do |key, analyzer_info|
      refute_nil analyzer_info[:class], "Analyzer #{key} missing :class"
      refute_nil analyzer_info[:metadata], "Analyzer #{key} missing :metadata"
      assert_kind_of Hash, analyzer_info[:metadata], "Analyzer #{key} metadata should be Hash"
    end
  end
end
