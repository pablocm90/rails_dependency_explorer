# frozen_string_literal: true

require 'test_helper'

class DependencyStatisticsCalculatorInterfaceIntegrationTest < Minitest::Test
  def setup
    @dependency_data = {
      "UserController" => [{"User" => ["find", "create"]}, {"AuthService" => ["authenticate"]}],
      "User" => [{"Database" => ["save", "find"]}, {"Validator" => ["validate"]}],
      "AuthService" => [{"User" => ["find"]}, {"TokenService" => ["generate"]}],
      "TokenService" => [{"Crypto" => ["encrypt"]}],
      "Database" => [],
      "Validator" => [{"ValidationRules" => ["check"]}],
      "ValidationRules" => [],
      "Crypto" => []
    }
    @analyzer = RailsDependencyExplorer::Analysis::DependencyStatisticsCalculator.new(@dependency_data)
  end

  def test_dependency_statistics_calculator_includes_statistics_analyzer_interface
    # Should include StatisticsAnalyzerInterface
    assert @analyzer.class.included_modules.include?(RailsDependencyExplorer::Analysis::StatisticsAnalyzerInterface)
  end

  def test_dependency_statistics_calculator_responds_to_statistics_interface_methods
    # Should respond to StatisticsAnalyzerInterface methods
    assert_respond_to @analyzer, :calculate_basic_statistics
    assert_respond_to @analyzer, :calculate_distribution
    assert_respond_to @analyzer, :calculate_summary_metrics
  end

  def test_dependency_statistics_calculator_can_calculate_basic_statistics
    # Should be able to calculate basic statistics using interface method
    stats = @analyzer.calculate_basic_statistics
    
    assert_kind_of Hash, stats
    assert_includes stats.keys, :total_classes
    assert_includes stats.keys, :total_dependencies
    assert_includes stats.keys, :average_dependencies_per_class
    assert_includes stats.keys, :max_dependencies
    assert_includes stats.keys, :min_dependencies
    
    # Verify basic statistics calculations
    assert_equal 8, stats[:total_classes]  # 8 classes in dependency data
    assert_equal 8, stats[:total_dependencies]  # 8 total dependency relationships
    assert_equal 1.0, stats[:average_dependencies_per_class]  # 8 deps / 8 classes = 1.0
    assert_equal 2, stats[:max_dependencies]  # UserController and User have 2 deps each
    assert_equal 0, stats[:min_dependencies]  # Database, ValidationRules, Crypto have 0 deps
  end

  def test_dependency_statistics_calculator_can_calculate_distribution
    # Should be able to calculate distribution using interface method
    distribution = @analyzer.calculate_distribution
    
    assert_kind_of Hash, distribution
    assert_includes distribution.keys, :dependency_count_distribution
    assert_includes distribution.keys, :percentiles
    
    # Verify distribution calculations
    count_dist = distribution[:dependency_count_distribution]
    assert_kind_of Hash, count_dist
    assert_equal 3, count_dist[0]  # 3 classes with 0 dependencies (Database, ValidationRules, Crypto)
    assert_equal 2, count_dist[1]  # 2 classes with 1 dependency (TokenService, Validator)
    assert_equal 3, count_dist[2]  # 3 classes with 2 dependencies (UserController, User, AuthService)
    
    # Verify percentiles
    percentiles = distribution[:percentiles]
    assert_includes percentiles.keys, :p50
    assert_includes percentiles.keys, :p90
    assert_includes percentiles.keys, :p95
  end

  def test_dependency_statistics_calculator_can_calculate_summary_metrics
    # Should be able to calculate summary metrics using interface method
    metrics = @analyzer.calculate_summary_metrics
    
    assert_kind_of Hash, metrics
    assert_includes metrics.keys, :coupling_metrics
    assert_includes metrics.keys, :complexity_indicators
    assert_includes metrics.keys, :health_score

    # Verify coupling metrics
    coupling = metrics[:coupling_metrics]
    assert_includes coupling.keys, :average_fan_out
    assert_includes coupling.keys, :average_fan_in
    assert_includes coupling.keys, :coupling_ratio
    
    # Verify complexity indicators
    complexity = metrics[:complexity_indicators]
    assert_includes complexity.keys, :high_coupling_classes
    assert_includes complexity.keys, :isolated_classes
    
    # Verify health score
    health = metrics[:health_score]
    assert_kind_of Numeric, health
    assert health >= 0.0
    assert health <= 100.0
  end

  def test_dependency_statistics_calculator_maintains_existing_functionality
    # Should still work with existing statistics calculation methods
    assert_respond_to @analyzer, :calculate_statistics
    
    # Should calculate statistics correctly using existing method
    stats = @analyzer.calculate_statistics
    assert_kind_of Hash, stats
    
    # Verify existing functionality is preserved
    assert_includes stats.keys, :total_classes
    assert_includes stats.keys, :total_dependencies
    assert_includes stats.keys, :most_used_dependency
    assert_includes stats.keys, :dependency_counts
  end

  def test_dependency_statistics_calculator_interface_complements_existing_analysis
    # Interface methods should provide additional insights beyond existing analysis
    existing_stats = @analyzer.calculate_statistics
    basic_stats = @analyzer.calculate_basic_statistics
    distribution = @analyzer.calculate_distribution
    summary_metrics = @analyzer.calculate_summary_metrics
    
    # Basic statistics should be consistent with existing analysis
    assert_equal existing_stats[:total_classes], basic_stats[:total_classes]
    # Note: total_dependencies calculation may differ between existing and interface methods
    
    # Interface should provide additional insights
    assert_includes distribution.keys, :percentiles  # Not in existing analysis
    assert_includes summary_metrics.keys, :health_score  # Not in existing analysis
    assert_includes summary_metrics.keys, :coupling_metrics  # Enhanced analysis
  end

  def test_dependency_statistics_calculator_can_use_both_interfaces
    # Should be able to use both existing and new interface methods
    
    # Use existing interface
    existing_stats = @analyzer.calculate_statistics
    
    # Use statistics interface
    basic_stats = @analyzer.calculate_basic_statistics
    distribution = @analyzer.calculate_distribution
    summary_metrics = @analyzer.calculate_summary_metrics
    
    # Both should provide consistent core information
    assert existing_stats[:total_classes] > 0
    assert_equal existing_stats[:total_classes], basic_stats[:total_classes]
    assert distribution[:dependency_count_distribution].values.sum == basic_stats[:total_classes]
    assert_kind_of Numeric, summary_metrics[:health_score]
  end

  def test_dependency_statistics_calculator_interface_methods_work_with_empty_data
    empty_analyzer = RailsDependencyExplorer::Analysis::DependencyStatisticsCalculator.new({})
    
    # Statistics interface methods should handle empty data
    basic_stats = empty_analyzer.calculate_basic_statistics
    assert_equal 0, basic_stats[:total_classes]
    assert_equal 0, basic_stats[:total_dependencies]
    assert_equal 0, basic_stats[:average_dependencies_per_class]
    
    distribution = empty_analyzer.calculate_distribution
    assert_equal({}, distribution[:dependency_count_distribution])
    
    summary_metrics = empty_analyzer.calculate_summary_metrics
    assert_equal 100, summary_metrics[:health_score]  # Empty data gets perfect health score
  end

  def test_dependency_statistics_calculator_interface_methods_work_with_single_class
    single_class_data = {"SingleClass" => []}
    single_analyzer = RailsDependencyExplorer::Analysis::DependencyStatisticsCalculator.new(single_class_data)
    
    # Statistics interface should handle single class data
    basic_stats = single_analyzer.calculate_basic_statistics
    assert_equal 1, basic_stats[:total_classes]
    assert_equal 0, basic_stats[:total_dependencies]
    assert_equal 0.0, basic_stats[:average_dependencies_per_class]
    assert_equal 0, basic_stats[:max_dependencies]
    assert_equal 0, basic_stats[:min_dependencies]
    
    distribution = single_analyzer.calculate_distribution
    assert_equal({0 => 1}, distribution[:dependency_count_distribution])
    
    summary_metrics = single_analyzer.calculate_summary_metrics
    assert_kind_of Numeric, summary_metrics[:health_score]
  end

  def test_dependency_statistics_calculator_interface_provides_enhanced_analysis
    # Interface should provide more detailed analysis than existing methods
    existing_stats = @analyzer.calculate_statistics
    summary_metrics = @analyzer.calculate_summary_metrics
    
    # Should provide coupling analysis
    coupling = summary_metrics[:coupling_metrics]
    assert_kind_of Numeric, coupling[:average_fan_out]
    assert_kind_of Numeric, coupling[:average_fan_in]
    assert_kind_of Numeric, coupling[:coupling_ratio]
    
    # Should provide complexity analysis
    complexity = summary_metrics[:complexity_indicators]
    assert_kind_of Array, complexity[:high_coupling_classes]
    assert_kind_of Array, complexity[:isolated_classes]
    
    # Should provide health scoring
    health_score = summary_metrics[:health_score]
    assert health_score.between?(0.0, 100.0)
    
    # Enhanced analysis should go beyond basic distribution
    distribution = @analyzer.calculate_distribution
    percentiles = distribution[:percentiles]
    assert_kind_of Numeric, percentiles[:p50]
    assert_kind_of Numeric, percentiles[:p90]
    assert_kind_of Numeric, percentiles[:p95]
  end

  def test_dependency_statistics_calculator_statistics_interface_identifies_patterns
    # Interface should identify architectural patterns and issues
    summary_metrics = @analyzer.calculate_summary_metrics
    
    # Should identify isolated classes
    complexity = summary_metrics[:complexity_indicators]
    isolated_classes = complexity[:isolated_classes]

    # Classes with no dependencies should be identified as isolated
    classes_without_deps = @dependency_data.select { |_, deps| deps.empty? }.keys

    classes_without_deps.each do |class_name|
      assert_includes isolated_classes, class_name, "#{class_name} should be identified as isolated"
    end

    # Should identify high coupling classes (if any)
    high_coupling_classes = complexity[:high_coupling_classes]
    assert_kind_of Array, high_coupling_classes
  end
end
