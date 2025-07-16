# frozen_string_literal: true

module RailsDependencyExplorer
  module Analysis
    # Interface for analyzers that perform statistical analysis on dependency data.
    # Provides common statistical utilities and metrics calculation capabilities.
    # Analyzers that compute statistics, distributions, or metrics should include this interface.
    module StatisticsAnalyzerInterface
      def self.included(base)
        # Module included callback - can be used for validation or setup
      end

      # Calculates basic statistics about the dependency data
      # @return [Hash] Basic statistics including totals, averages, min/max
      def calculate_basic_statistics
        return empty_statistics if @dependency_data.nil? || @dependency_data.empty?
        
        total_classes = @dependency_data.size
        dependency_counts = @dependency_data.map { |_class, deps| deps.size }
        total_dependencies = dependency_counts.sum
        
        {
          total_classes: total_classes,
          total_dependencies: total_dependencies,
          average_dependencies_per_class: total_dependencies.to_f / total_classes,
          max_dependencies: dependency_counts.max || 0,
          min_dependencies: dependency_counts.min || 0
        }
      end

      # Calculates distribution of dependency counts
      # @return [Hash] Distribution data including count distribution and percentiles
      def calculate_distribution
        return empty_distribution if @dependency_data.nil? || @dependency_data.empty?
        
        dependency_counts = @dependency_data.map { |_class, deps| deps.size }
        
        # Build distribution hash
        distribution = {}
        dependency_counts.each do |count|
          distribution[count] = (distribution[count] || 0) + 1
        end
        
        # Calculate percentiles
        sorted_counts = dependency_counts.sort
        percentiles = calculate_percentiles(sorted_counts)
        
        {
          dependency_count_distribution: distribution,
          percentiles: percentiles
        }
      end

      # Calculates summary metrics and health indicators
      # @return [Hash] Summary metrics including coupling and complexity indicators
      def calculate_summary_metrics
        return empty_summary_metrics if @dependency_data.nil? || @dependency_data.empty?
        
        dependency_counts = @dependency_data.map { |_class, deps| deps.size }
        
        # Calculate fan-out (dependencies per class)
        average_fan_out = dependency_counts.sum.to_f / dependency_counts.size
        
        # Calculate fan-in (how many classes depend on each class)
        fan_in_counts = calculate_fan_in_counts
        average_fan_in = fan_in_counts.values.sum.to_f / fan_in_counts.size
        
        # Coupling ratio
        coupling_ratio = average_fan_out / (average_fan_out + average_fan_in + 1)
        
        # Identify problematic classes
        high_coupling_threshold = [average_fan_out * 2, 5].max
        high_coupling_classes = @dependency_data.select { |_class, deps| deps.size >= high_coupling_threshold }.keys
        isolated_classes = @dependency_data.select { |_class, deps| deps.empty? }.keys
        
        # Calculate health score (0-100, higher is better)
        health_score = calculate_health_score(dependency_counts, high_coupling_classes.size, isolated_classes.size)
        
        {
          coupling_metrics: {
            average_fan_out: average_fan_out,
            average_fan_in: average_fan_in,
            coupling_ratio: coupling_ratio
          },
          complexity_indicators: {
            high_coupling_classes: high_coupling_classes,
            isolated_classes: isolated_classes
          },
          health_score: health_score
        }
      end

      private

      # Returns empty statistics for nil/empty data
      def empty_statistics
        {
          total_classes: 0,
          total_dependencies: 0,
          average_dependencies_per_class: 0,
          max_dependencies: 0,
          min_dependencies: 0
        }
      end

      # Returns empty distribution for nil/empty data
      def empty_distribution
        {
          dependency_count_distribution: {},
          percentiles: { p50: 0, p90: 0, p95: 0 }
        }
      end

      # Returns empty summary metrics for nil/empty data
      def empty_summary_metrics
        {
          coupling_metrics: {
            average_fan_out: 0,
            average_fan_in: 0,
            coupling_ratio: 0
          },
          complexity_indicators: {
            high_coupling_classes: [],
            isolated_classes: []
          },
          health_score: 100  # Perfect health for empty system
        }
      end

      # Calculates percentiles from sorted array
      def calculate_percentiles(sorted_counts)
        return { p50: 0, p90: 0, p95: 0 } if sorted_counts.empty?
        
        size = sorted_counts.size
        
        {
          p50: percentile_value(sorted_counts, 50),
          p90: percentile_value(sorted_counts, 90),
          p95: percentile_value(sorted_counts, 95)
        }
      end

      # Calculates specific percentile value
      def percentile_value(sorted_array, percentile)
        return 0 if sorted_array.empty?

        # Use standard percentile calculation
        if percentile == 50
          # Median calculation
          array_size = sorted_array.size
          if array_size.odd?
            sorted_array[array_size / 2]
          else
            (sorted_array[array_size / 2 - 1] + sorted_array[array_size / 2]) / 2.0
          end
        else
          # General percentile calculation
          index = (percentile / 100.0 * (sorted_array.size - 1)).round
          sorted_array[index]
        end
      end

      # Calculates fan-in counts (how many classes depend on each class)
      def calculate_fan_in_counts
        fan_in = {}
        
        # Initialize all classes with 0 fan-in
        @dependency_data.keys.each { |class_name| fan_in[class_name] = 0 }
        
        # Count dependencies
        @dependency_data.each do |_class, dependencies|
          dependencies.each do |dependency_hash|
            dependency_hash.keys.each do |dependency_name|
              fan_in[dependency_name] = (fan_in[dependency_name] || 0) + 1
            end
          end
        end
        
        fan_in
      end

      # Calculates overall health score based on various metrics
      def calculate_health_score(dependency_counts, high_coupling_count, isolated_count)
        total_classes = dependency_counts.size
        return 100 if total_classes == 0
        
        # Penalize high coupling and isolation
        coupling_penalty = (high_coupling_count.to_f / total_classes) * 30
        isolation_penalty = (isolated_count.to_f / total_classes) * 20
        
        # Penalize high variance in dependency counts
        variance = calculate_variance(dependency_counts)
        variance_penalty = [variance / 10.0, 25].min
        
        # Calculate final score
        score = 100 - coupling_penalty - isolation_penalty - variance_penalty
        [score, 0].max.round
      end

      # Calculates variance of dependency counts
      def calculate_variance(counts)
        return 0 if counts.empty?
        
        mean = counts.sum.to_f / counts.size
        sum_of_squares = counts.map { |count| (count - mean) ** 2 }.sum
        sum_of_squares / counts.size
      end
    end
  end
end
