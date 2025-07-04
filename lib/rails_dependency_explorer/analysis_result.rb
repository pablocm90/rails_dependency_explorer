# frozen_string_literal: true

require_relative "dependency_visualizer"

module RailsDependencyExplorer
  class AnalysisResult
    def initialize(dependency_data)
      @dependency_data = dependency_data
    end

    def to_graph
      visualizer = DependencyVisualizer.new
      visualizer.to_graph(@dependency_data)
    end
  end
end
