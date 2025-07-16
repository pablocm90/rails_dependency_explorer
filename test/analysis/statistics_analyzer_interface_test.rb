# frozen_string_literal: true

require 'test_helper'
require_relative '../../lib/rails_dependency_explorer/analysis/statistics_analyzer_interface'

class StatisticsAnalyzerInterfaceTest < Minitest::Test
  def test_statistics_analyzer_interface_exists
    # Interface should be defined
    assert_kind_of Module, RailsDependencyExplorer::Analysis::StatisticsAnalyzerInterface
  end

  def test_statistics_analyzer_interface_defines_required_methods
    interface = RailsDependencyExplorer::Analysis::StatisticsAnalyzerInterface
    
    # Should define method requirements for statistics analysis
    assert_respond_to interface, :included
    
    # When included, should add required methods
    test_class = Class.new do
      include RailsDependencyExplorer::Analysis::StatisticsAnalyzerInterface
    end
    
    instance = test_class.new
    
    # Should require calculate_basic_statistics method
    assert_respond_to instance, :calculate_basic_statistics
    
    # Should require calculate_distribution method
    assert_respond_to instance, :calculate_distribution
    
    # Should require calculate_summary_metrics method
    assert_respond_to instance, :calculate_summary_metrics
  end

  def test_statistics_analyzer_interface_provides_basic_statistics
    test_class = Class.new do
      include RailsDependencyExplorer::Analysis::StatisticsAnalyzerInterface
      
      def initialize(dependency_data)
        @dependency_data = dependency_data
      end
    end
    
    dependency_data = {
      "A" => [{"B" => ["method1"]}, {"C" => ["method2"]}],
      "B" => [{"C" => ["method3"]}],
      "C" => [],
      "D" => [{"A" => ["method4"]}, {"B" => ["method5"]}, {"C" => ["method6"]}]
    }
    
    instance = test_class.new(dependency_data)
    
    # Should calculate basic statistics
    stats = instance.calculate_basic_statistics
    
    assert_kind_of Hash, stats
    assert_includes stats.keys, :total_classes
    assert_includes stats.keys, :total_dependencies
    assert_includes stats.keys, :average_dependencies_per_class
    assert_includes stats.keys, :max_dependencies
    assert_includes stats.keys, :min_dependencies
    
    # Should have correct values
    assert_equal 4, stats[:total_classes]
    assert_equal 6, stats[:total_dependencies]
    assert_equal 1.5, stats[:average_dependencies_per_class]
    assert_equal 3, stats[:max_dependencies]
    assert_equal 0, stats[:min_dependencies]
  end

  def test_statistics_analyzer_interface_provides_distribution_analysis
    test_class = Class.new do
      include RailsDependencyExplorer::Analysis::StatisticsAnalyzerInterface
      
      def initialize(dependency_data)
        @dependency_data = dependency_data
      end
    end
    
    dependency_data = {
      "A" => [{"B" => ["method1"]}],
      "B" => [{"C" => ["method2"]}],
      "C" => [],
      "D" => [{"A" => ["method3"]}, {"B" => ["method4"]}, {"C" => ["method5"]}]
    }
    
    instance = test_class.new(dependency_data)
    
    # Should calculate distribution
    distribution = instance.calculate_distribution
    
    assert_kind_of Hash, distribution
    assert_includes distribution.keys, :dependency_count_distribution
    assert_includes distribution.keys, :percentiles
    
    # Should show distribution of dependency counts
    dep_dist = distribution[:dependency_count_distribution]
    assert_equal 1, dep_dist[0]  # 1 class with 0 dependencies
    assert_equal 2, dep_dist[1]  # 2 classes with 1 dependency
    assert_equal 1, dep_dist[3]  # 1 class with 3 dependencies
    
    # Should include percentiles
    percentiles = distribution[:percentiles]
    assert_includes percentiles.keys, :p50
    assert_includes percentiles.keys, :p90
    assert_includes percentiles.keys, :p95
  end

  def test_statistics_analyzer_interface_provides_summary_metrics
    test_class = Class.new do
      include RailsDependencyExplorer::Analysis::StatisticsAnalyzerInterface
      
      def initialize(dependency_data)
        @dependency_data = dependency_data
      end
    end
    
    dependency_data = {
      "A" => [{"B" => ["method1"]}, {"C" => ["method2"]}],
      "B" => [{"C" => ["method3"]}],
      "C" => []
    }
    
    instance = test_class.new(dependency_data)
    
    # Should calculate summary metrics
    summary = instance.calculate_summary_metrics
    
    assert_kind_of Hash, summary
    assert_includes summary.keys, :coupling_metrics
    assert_includes summary.keys, :complexity_indicators
    assert_includes summary.keys, :health_score
    
    # Should include coupling metrics
    coupling = summary[:coupling_metrics]
    assert_includes coupling.keys, :average_fan_out
    assert_includes coupling.keys, :average_fan_in
    assert_includes coupling.keys, :coupling_ratio
    
    # Should include complexity indicators
    complexity = summary[:complexity_indicators]
    assert_includes complexity.keys, :high_coupling_classes
    assert_includes complexity.keys, :isolated_classes
    
    # Should include health score
    assert_kind_of Numeric, summary[:health_score]
    assert summary[:health_score] >= 0
    assert summary[:health_score] <= 100
  end

  def test_statistics_analyzer_interface_handles_empty_data
    test_class = Class.new do
      include RailsDependencyExplorer::Analysis::StatisticsAnalyzerInterface
      
      def initialize(dependency_data)
        @dependency_data = dependency_data
      end
    end
    
    instance = test_class.new({})
    
    # Should handle empty dependency data gracefully
    stats = instance.calculate_basic_statistics
    assert_equal 0, stats[:total_classes]
    assert_equal 0, stats[:total_dependencies]
    assert_equal 0, stats[:average_dependencies_per_class]
    
    distribution = instance.calculate_distribution
    assert_equal({}, distribution[:dependency_count_distribution])
    
    summary = instance.calculate_summary_metrics
    assert_equal 100, summary[:health_score]  # Perfect health for empty system
  end

  def test_statistics_analyzer_interface_calculates_percentiles_correctly
    test_class = Class.new do
      include RailsDependencyExplorer::Analysis::StatisticsAnalyzerInterface
      
      def initialize(dependency_data)
        @dependency_data = dependency_data
      end
    end
    
    # Create data with known distribution: 0, 1, 1, 2, 3, 5, 8 dependencies
    dependency_data = {
      "A" => [],  # 0 deps
      "B" => [{"X" => ["m1"]}],  # 1 dep
      "C" => [{"Y" => ["m2"]}],  # 1 dep
      "D" => [{"X" => ["m3"]}, {"Y" => ["m4"]}],  # 2 deps
      "E" => [{"X" => ["m5"]}, {"Y" => ["m6"]}, {"Z" => ["m7"]}],  # 3 deps
      "F" => [{"X1" => ["m1"]}, {"X2" => ["m2"]}, {"X3" => ["m3"]}, {"X4" => ["m4"]}, {"X5" => ["m5"]}],  # 5 deps
      "G" => [{"X1" => ["m1"]}, {"X2" => ["m2"]}, {"X3" => ["m3"]}, {"X4" => ["m4"]}, {"X5" => ["m5"]}, {"X6" => ["m6"]}, {"X7" => ["m7"]}, {"X8" => ["m8"]}]   # 8 deps
    }
    
    instance = test_class.new(dependency_data)
    
    distribution = instance.calculate_distribution
    percentiles = distribution[:percentiles]
    
    # Should calculate percentiles correctly
    # For sorted array [0, 1, 1, 2, 3, 5, 8]:
    # - Median (p50) is the middle value: 2 (4th element in 7-element array)
    # - p90 is at index 5.4 ≈ 5: value 5
    # - p95 is at index 5.7 ≈ 6: value 8
    assert_equal 2, percentiles[:p50]  # Median
    assert_equal 5, percentiles[:p90]  # 90th percentile
    assert_equal 8, percentiles[:p95]  # 95th percentile
  end
end
