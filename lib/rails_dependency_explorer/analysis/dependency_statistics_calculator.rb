# frozen_string_literal: true

module RailsDependencyExplorer
  module Analysis
    # Calculates statistical metrics for dependency analysis results.
    # Provides insights into dependency patterns, including dependency counts,
    # distribution statistics, and other metrics useful for code quality assessment.
    class DependencyStatisticsCalculator
      def initialize(dependency_data)
        @dependency_data = dependency_data
      end

      def calculate_statistics
        dependency_counts = calculate_dependency_counts
        most_used = dependency_counts.max_by { |_, count| count }

        {
          total_classes: @dependency_data.keys.count,
          total_dependencies: dependency_counts.keys.count,
          most_used_dependency: most_used ? most_used[0] : nil,
          dependency_counts: dependency_counts
        }
      end

      def self.count_hash_dependencies(dep, counts)
        dep.each do |constant, methods|
          counts[constant] += 1
        end
      end

      private

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
