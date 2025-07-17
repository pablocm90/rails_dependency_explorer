# frozen_string_literal: true

require "minitest/autorun"
require "benchmark"
require_relative "../test_helper"

# Performance tests for AnalysisPipeline to ensure pipeline architecture maintains good performance.
# Establishes baseline measurements and verifies performance optimizations.
# Part of Phase 3.4 performance optimization (Behavioral changes).
class AnalysisPipelinePerformanceTest < Minitest::Test
  def setup
    # Create realistic dependency data for performance testing
    @small_dependency_data = create_dependency_data(10)   # 10 classes
    @medium_dependency_data = create_dependency_data(50)  # 50 classes
    @large_dependency_data = create_dependency_data(200)  # 200 classes
  end

  def test_pipeline_execution_performance_baseline
    # Test that pipeline execution completes within reasonable time limits
    # This establishes our performance baseline before optimizations
    
    analyzers = create_default_analyzers(@medium_dependency_data)
    pipeline = RailsDependencyExplorer::Analysis::AnalysisPipeline.new(analyzers)
    
    # Measure execution time
    execution_time = Benchmark.realtime do
      results = pipeline.analyze(@medium_dependency_data)
      
      # Verify results are produced (not just measuring empty execution)
      assert_includes results.keys, :statistics
      assert_includes results.keys, :circular_dependencies
      assert_includes results.keys, :dependency_depth
    end
    
    # Performance requirement: Should complete within 2 seconds for medium dataset
    assert execution_time < 2.0, "Pipeline execution took #{execution_time}s, expected < 2.0s"
  end

  def test_pipeline_scales_linearly_with_data_size
    # Test that pipeline execution time scales reasonably with data size
    # This will help us identify performance bottlenecks
    
    small_time = measure_pipeline_execution(@small_dependency_data)
    medium_time = measure_pipeline_execution(@medium_dependency_data)
    large_time = measure_pipeline_execution(@large_dependency_data)
    
    # Performance requirement: Should scale roughly linearly (not exponentially)
    # Allow for some variance but catch exponential growth
    scaling_factor_small_to_medium = medium_time / small_time
    scaling_factor_medium_to_large = large_time / medium_time
    
    # Data size ratios: small(10) -> medium(50) = 5x, medium(50) -> large(200) = 4x
    # Time should not scale worse than 10x the data size ratio
    assert scaling_factor_small_to_medium < 50, "Poor scaling from small to medium: #{scaling_factor_small_to_medium}x"
    assert scaling_factor_medium_to_large < 40, "Poor scaling from medium to large: #{scaling_factor_medium_to_large}x"
  end

  def test_pipeline_memory_usage_is_reasonable
    # Test that pipeline doesn't consume excessive memory
    # This will be important for large codebases
    
    analyzers = create_default_analyzers(@large_dependency_data)
    pipeline = RailsDependencyExplorer::Analysis::AnalysisPipeline.new(analyzers)
    
    # Measure memory usage (basic approach - can be enhanced later)
    memory_before = get_memory_usage
    results = pipeline.analyze(@large_dependency_data)
    memory_after = get_memory_usage
    
    memory_increase = memory_after - memory_before
    
    # Performance requirement: Should not use more than 100MB for large dataset
    # This is a reasonable limit for a dependency analysis tool
    assert memory_increase < 100_000_000, "Memory usage too high: #{memory_increase} bytes"
    
    # Verify results were actually produced
    assert_includes results.keys, :statistics
  end

  def test_pipeline_supports_performance_configuration
    # Test that pipeline can be configured for performance optimization
    # This test will initially fail until we implement performance config

    # Performance-optimized configuration
    performance_config = {
      parallel_execution: true,
      enable_caching: true,
      memory_optimization: true
    }

    analyzers = create_default_analyzers(@medium_dependency_data)
    pipeline = RailsDependencyExplorer::Analysis::AnalysisPipeline.new(analyzers, config: performance_config)

    # Should accept performance configuration without errors
    assert_respond_to pipeline, :config
    assert_equal true, pipeline.config[:parallel_execution]
    assert_equal true, pipeline.config[:enable_caching]
    assert_equal true, pipeline.config[:memory_optimization]

    # Should still produce correct results with performance config
    results = pipeline.analyze(@medium_dependency_data)
    assert_includes results.keys, :statistics
    assert_includes results.keys, :circular_dependencies
  end

  def test_parallel_execution_works_correctly
    # Test that parallel execution produces the same results as sequential execution
    # and doesn't crash (performance improvement may vary based on dataset size and system)

    analyzers = create_default_analyzers(@medium_dependency_data)

    # Get sequential results
    sequential_pipeline = RailsDependencyExplorer::Analysis::AnalysisPipeline.new(analyzers, config: { parallel_execution: false })
    sequential_results = sequential_pipeline.analyze(@medium_dependency_data)

    # Get parallel results
    parallel_pipeline = RailsDependencyExplorer::Analysis::AnalysisPipeline.new(analyzers, config: { parallel_execution: true })
    parallel_results = parallel_pipeline.analyze(@medium_dependency_data)

    # Results should be equivalent (same keys and structure)
    assert_equal sequential_results.keys.sort, parallel_results.keys.sort

    # Verify specific result types are present
    assert_includes parallel_results.keys, :statistics
    assert_includes parallel_results.keys, :circular_dependencies
    assert_includes parallel_results.keys, :dependency_depth

    # Statistics should be consistent
    assert_equal sequential_results[:statistics][:total_classes], parallel_results[:statistics][:total_classes]
  end

  def test_caching_improves_repeated_analysis_performance
    # Test that caching improves performance for repeated analysis
    # This test will fail until we implement caching

    analyzers = create_default_analyzers(@medium_dependency_data)

    # Test without caching
    no_cache_pipeline = RailsDependencyExplorer::Analysis::AnalysisPipeline.new(analyzers, config: { enable_caching: false })
    no_cache_time = Benchmark.realtime do
      2.times { no_cache_pipeline.analyze(@medium_dependency_data) }
    end

    # Test with caching
    cached_pipeline = RailsDependencyExplorer::Analysis::AnalysisPipeline.new(analyzers, config: { enable_caching: true })
    cached_time = Benchmark.realtime do
      2.times { cached_pipeline.analyze(@medium_dependency_data) }
    end

    # Cached execution should be faster for repeated analysis
    improvement_ratio = no_cache_time / cached_time
    assert improvement_ratio > 1.2, "Caching should improve repeated analysis. No cache: #{no_cache_time}s, Cached: #{cached_time}s, Ratio: #{improvement_ratio}"
  end

  private

  def create_dependency_data(class_count)
    # Create realistic dependency data for performance testing
    dependency_data = {}
    
    (1..class_count).each do |i|
      class_name = "Class#{i}"
      dependencies = []
      
      # Create realistic dependency patterns
      # Each class depends on 1-5 other classes
      dependency_count = rand(1..5)
      dependency_count.times do |j|
        target_class = "Class#{rand(1..class_count)}"
        next if target_class == class_name # Avoid self-dependencies
        
        dependencies << { target_class => ["method#{j}"] }
      end
      
      dependency_data[class_name] = dependencies
    end
    
    dependency_data
  end

  def create_default_analyzers(dependency_data)
    # Create the standard set of analyzers for performance testing
    [
      RailsDependencyExplorer::Analysis::DependencyStatisticsCalculator.new(dependency_data, include_metadata: false),
      RailsDependencyExplorer::Analysis::CircularDependencyAnalyzer.new(dependency_data, include_metadata: false),
      RailsDependencyExplorer::Analysis::DependencyDepthAnalyzer.new(dependency_data, include_metadata: false),
      RailsDependencyExplorer::Analysis::RailsComponentAnalyzer.new(dependency_data, include_metadata: false),
      RailsDependencyExplorer::Analysis::ActiveRecordRelationshipAnalyzer.new(dependency_data, include_metadata: false)
    ]
  end

  def measure_pipeline_execution(dependency_data)
    # Measure execution time for pipeline with given data
    analyzers = create_default_analyzers(dependency_data)
    pipeline = RailsDependencyExplorer::Analysis::AnalysisPipeline.new(analyzers)
    
    Benchmark.realtime do
      pipeline.analyze(dependency_data)
    end
  end

  def get_memory_usage
    # Basic memory usage measurement (can be enhanced with more sophisticated tools)
    # Returns memory usage in bytes
    if defined?(GC.stat)
      stat = GC.stat
      pages = stat[:heap_allocated_pages] || stat[:heap_live_slots] || 0
      page_size = stat[:heap_page_size] || 4096  # Default page size
      pages * page_size
    else
      # Fallback for environments without GC.stat
      0
    end
  end
end
