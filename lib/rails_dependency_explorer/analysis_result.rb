# frozen_string_literal: true

require_relative "dependency_visualizer"

module RailsDependencyExplorer
  class AnalysisResult
    def initialize(dependency_data)
      @dependency_data = dependency_data
    end

    def to_graph
      visualizer.to_graph(@dependency_data)
    end

    def to_dot
      visualizer.to_dot(@dependency_data)
    end

    def statistics
      dependency_counts = calculate_dependency_counts
      most_used = dependency_counts.max_by { |_, count| count }

      {
        total_classes: @dependency_data.keys.count,
        total_dependencies: dependency_counts.keys.count,
        most_used_dependency: most_used ? most_used[0] : nil,
        dependency_counts: dependency_counts
      }
    end

    private

    def visualizer
      @visualizer ||= DependencyVisualizer.new
    end

    def calculate_dependency_counts
      counts = Hash.new(0)

      @dependency_data.each do |class_name, dependencies|
        dependencies.each do |dep|
          if dep.is_a?(Hash)
            dep.each do |constant, methods|
              # Count each occurrence of the constant (once per dependency hash)
              counts[constant] += 1
            end
          end
        end
      end

      counts
    end
  end
end
