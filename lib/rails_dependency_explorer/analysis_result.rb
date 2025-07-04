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

    private

    def visualizer
      @visualizer ||= DependencyVisualizer.new
    end
  end
end
