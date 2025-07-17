# frozen_string_literal: true

require "test_helper"

# Tests for removing PipelineAnalyzerAdapter by using analyzers directly in pipeline.
# Verifies that all analyzers can work directly with AnalysisPipeline without adapter.
# Part of Phase 3.3.4 architectural refactoring (Tidy First - Structural changes).
class PipelineAnalyzerAdapterRemovalTest < Minitest::Test
  def setup
    @dependency_data = {
      "User" => [
        {"ApplicationRecord" => ["validates"]},
        {"ActiveRecord::has_many" => ["Post", "Comment"]},
        {"ActiveRecord::belongs_to" => ["Account"]}
      ],
      "Post" => [
        {"ApplicationRecord" => ["validates"]},
        {"ActiveRecord::belongs_to" => ["User"]},
        {"ActiveRecord::has_many" => ["Comment"]}
      ],
      "Comment" => [
        {"ApplicationRecord" => ["validates"]},
        {"ActiveRecord::belongs_to" => ["Post", "User"]}
      ],
      "UserController" => [
        {"ApplicationController" => ["before_action"]},
        {"User" => ["find", "create"]},
        {"UserService" => ["process"]}
      ],
      "UserService" => [
        {"User" => ["new", "save"]},
        {"EmailService" => ["send_notification"]}
      ]
    }
  end

  def test_pipeline_works_directly_with_statistics_analyzer
    # Test that DependencyStatisticsCalculator can work directly with pipeline
    analyzer = RailsDependencyExplorer::Analysis::DependencyStatisticsCalculator.new(@dependency_data, include_metadata: false)
    pipeline = RailsDependencyExplorer::Analysis::AnalysisPipeline.new([analyzer])

    results = pipeline.analyze(@dependency_data)

    # Should produce statistics results directly (raw results, not metadata-wrapped)
    assert_includes results.keys, :statistics
    assert_kind_of Hash, results[:statistics]
    assert results[:statistics].key?(:total_classes)
    # Should NOT be metadata-wrapped
    refute_includes results[:statistics].keys, :result
    refute_includes results[:statistics].keys, :metadata
  end

  def test_pipeline_works_directly_with_circular_dependency_analyzer
    # Test that CircularDependencyAnalyzer can work directly with pipeline
    analyzer = RailsDependencyExplorer::Analysis::CircularDependencyAnalyzer.new(@dependency_data, include_metadata: false)
    pipeline = RailsDependencyExplorer::Analysis::AnalysisPipeline.new([analyzer])

    results = pipeline.analyze(@dependency_data)

    # Should produce circular dependencies results directly (raw results, not metadata-wrapped)
    assert_includes results.keys, :circular_dependencies
    assert_kind_of Array, results[:circular_dependencies]
    # Should NOT be metadata-wrapped
    refute results[:circular_dependencies].is_a?(Hash) && results[:circular_dependencies].key?(:result)
  end

  def test_pipeline_works_directly_with_dependency_depth_analyzer
    # Test that DependencyDepthAnalyzer can work directly with pipeline
    analyzer = RailsDependencyExplorer::Analysis::DependencyDepthAnalyzer.new(@dependency_data)
    pipeline = RailsDependencyExplorer::Analysis::AnalysisPipeline.new([analyzer])
    
    results = pipeline.analyze(@dependency_data)
    
    # Should produce dependency depth results directly
    assert_includes results.keys, :dependency_depth
    assert_kind_of Hash, results[:dependency_depth]
  end

  def test_pipeline_works_directly_with_rails_component_analyzer
    # Test that RailsComponentAnalyzer can work directly with pipeline
    analyzer = RailsDependencyExplorer::Analysis::RailsComponentAnalyzer.new(@dependency_data)
    pipeline = RailsDependencyExplorer::Analysis::AnalysisPipeline.new([analyzer])
    
    results = pipeline.analyze(@dependency_data)
    
    # Should produce rails components results directly
    assert_includes results.keys, :rails_components
    assert_kind_of Hash, results[:rails_components]
  end

  def test_pipeline_works_directly_with_activerecord_relationship_analyzer
    # Test that ActiveRecordRelationshipAnalyzer can work directly with pipeline
    analyzer = RailsDependencyExplorer::Analysis::ActiveRecordRelationshipAnalyzer.new(@dependency_data)
    pipeline = RailsDependencyExplorer::Analysis::AnalysisPipeline.new([analyzer])
    
    results = pipeline.analyze(@dependency_data)
    
    # Should produce activerecord relationships results directly
    assert_includes results.keys, :activerecord_relationships
    assert_kind_of Hash, results[:activerecord_relationships]
  end

  def test_pipeline_works_directly_with_cross_namespace_cycle_analyzer
    # Test that CrossNamespaceCycleAnalyzer can work directly with pipeline
    analyzer = RailsDependencyExplorer::ArchitecturalAnalysis::CrossNamespaceCycleAnalyzer.new(@dependency_data)
    pipeline = RailsDependencyExplorer::Analysis::AnalysisPipeline.new([analyzer])

    results = pipeline.analyze(@dependency_data)

    # Should produce cross namespace cycles results directly
    assert_includes results.keys, :cross_namespace_cycles
    assert_kind_of Array, results[:cross_namespace_cycles]
  end

  def test_pipeline_works_with_multiple_analyzers_directly
    # Test that pipeline can work with multiple analyzers directly without adapter
    analyzers = [
      RailsDependencyExplorer::Analysis::DependencyStatisticsCalculator.new(@dependency_data, include_metadata: false),
      RailsDependencyExplorer::Analysis::CircularDependencyAnalyzer.new(@dependency_data, include_metadata: false),
      RailsDependencyExplorer::Analysis::RailsComponentAnalyzer.new(@dependency_data, include_metadata: false),
      RailsDependencyExplorer::Analysis::ActiveRecordRelationshipAnalyzer.new(@dependency_data, include_metadata: false)
    ]

    pipeline = RailsDependencyExplorer::Analysis::AnalysisPipeline.new(analyzers)
    results = pipeline.analyze(@dependency_data)

    # Should produce all expected results
    assert_includes results.keys, :statistics
    assert_includes results.keys, :circular_dependencies
    assert_includes results.keys, :rails_components
    assert_includes results.keys, :activerecord_relationships

    # All results should be properly formatted (raw results, not metadata-wrapped)
    assert_kind_of Hash, results[:statistics]
    assert_kind_of Array, results[:circular_dependencies]
    assert_kind_of Hash, results[:rails_components]
    assert_kind_of Hash, results[:activerecord_relationships]

    # Should NOT be metadata-wrapped
    refute_includes results[:statistics].keys, :result if results[:statistics].respond_to?(:keys)
    refute_includes results[:rails_components].keys, :result if results[:rails_components].respond_to?(:keys)
    refute_includes results[:activerecord_relationships].keys, :result if results[:activerecord_relationships].respond_to?(:keys)
  end

  def test_analysis_result_build_pipeline_analyzers_without_adapter
    # Test that build_pipeline_analyzers method can create analyzers without adapter
    analyzers = RailsDependencyExplorer::Analysis::AnalysisResult.send(:build_pipeline_analyzers, @dependency_data, nil)

    # Should create analyzers directly, not wrapped in adapters
    analyzers.each do |analyzer|
      # Should not be wrapped in adapter (adapter class should not exist)
      assert analyzer.respond_to?(:analyze), "Analyzer #{analyzer.class} should respond to #analyze"
    end

    # Should have expected analyzer types
    analyzer_classes = analyzers.map(&:class)
    assert_includes analyzer_classes, RailsDependencyExplorer::Analysis::DependencyStatisticsCalculator
    assert_includes analyzer_classes, RailsDependencyExplorer::Analysis::CircularDependencyAnalyzer
    assert_includes analyzer_classes, RailsDependencyExplorer::Analysis::DependencyDepthAnalyzer
    assert_includes analyzer_classes, RailsDependencyExplorer::Analysis::RailsComponentAnalyzer
    assert_includes analyzer_classes, RailsDependencyExplorer::Analysis::ActiveRecordRelationshipAnalyzer
    assert_includes analyzer_classes, RailsDependencyExplorer::ArchitecturalAnalysis::CrossNamespaceCycleAnalyzer
  end

  def test_build_pipeline_analyzers_creates_analyzers_with_raw_results
    # Test that build_pipeline_analyzers creates analyzers configured to return raw results
    analyzers = RailsDependencyExplorer::Analysis::AnalysisResult.send(:build_pipeline_analyzers, @dependency_data, nil)

    # Each analyzer should be configured to return raw results (not metadata-wrapped)
    analyzers.each do |analyzer|
      result = analyzer.analyze(@dependency_data)

      # Should return raw results, not metadata-wrapped results
      if analyzer.respond_to?(:analyzer_key)
        case analyzer.analyzer_key
        when :statistics
          assert_kind_of Hash, result
          assert result.key?(:total_classes), "Statistics should have :total_classes key"
          refute result.key?(:result), "Should not be metadata-wrapped with :result key"
          refute result.key?(:metadata), "Should not be metadata-wrapped with :metadata key"
        when :circular_dependencies
          assert_kind_of Array, result
          refute result.is_a?(Hash) && result.key?(:result), "Should not be metadata-wrapped"
        when :rails_components
          assert_kind_of Hash, result
          assert result.key?(:controllers) || result.key?(:models), "Should have component categories"
          refute result.key?(:result), "Should not be metadata-wrapped with :result key"
        end
      end
    end
  end

  def test_pipeline_analyzer_adapter_class_should_not_exist
    # Test that PipelineAnalyzerAdapter class should be removed
    # This test should fail in RED phase (adapter still exists) and pass in GREEN phase (adapter removed)
    assert_raises(NameError) do
      RailsDependencyExplorer::Analysis::AnalysisResult::PipelineAnalyzerAdapter
    end
  end
end
