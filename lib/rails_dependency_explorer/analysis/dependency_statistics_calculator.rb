# frozen_string_literal: true

require_relative "base_analyzer"
require_relative "statistics_interface"

module RailsDependencyExplorer
  module Analysis
    # Calculates statistical metrics for dependency analysis results.
    # Provides insights into dependency patterns, including dependency counts,
    # distribution statistics, and other metrics useful for code quality assessment.
    class DependencyStatisticsCalculator < BaseAnalyzer
      include StatisticsInterface

      # Implementation of BaseAnalyzer template method
      def perform_analysis
        calculate_statistics
      end

      def calculate_statistics
        dependency_counts = calculate_dependency_counts

        {
          total_classes: @dependency_data.keys.count,
          total_dependencies: dependency_counts.keys.count,
          most_used_dependency: find_most_used_dependency(dependency_counts),
          dependency_counts: dependency_counts
        }
      end

      def self.count_hash_dependencies(dep, counts)
        dep.each do |constant, methods|
          counts[constant] += 1
        end
      end

      private

      # Find the most frequently used dependency
      def find_most_used_dependency(dependency_counts)
        most_used = dependency_counts.max_by { |_, count| count }
        most_used ? most_used[0] : nil
      end

      def calculate_dependency_counts
        counts = Hash.new(0)
        process_dependency_data(counts)
        counts
      end

      def process_dependency_data(counts)
        @dependency_data.each do |class_name, dependencies|
          dependencies.each do |dep|
            self.class.count_hash_dependencies(dep, counts) if dep.is_a?(Hash)
          end
        end
      end
    end
  end
end
