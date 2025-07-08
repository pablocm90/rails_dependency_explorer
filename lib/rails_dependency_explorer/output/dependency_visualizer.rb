# frozen_string_literal: true

require "set"
require "json"
require_relative "dependency_graph_adapter"
require_relative "dot_format_adapter"

module RailsDependencyExplorer
  module Output
    class DependencyVisualizer
      def to_graph(dependency_data)
        graph_adapter.to_graph(dependency_data)
      end

      def to_dot(dependency_data)
        graph = to_graph(dependency_data)
        dot_adapter.format(graph)
      end

      def to_json(dependency_data, statistics = nil)
        json_data = {
          "dependencies" => build_dependencies_hash(dependency_data),
          "statistics" => statistics
        }
        JSON.generate(json_data)
      end

      private

      def graph_adapter
        @graph_adapter ||= DependencyGraphAdapter.new
      end

      def dot_adapter
        @dot_adapter ||= DotFormatAdapter.new
      end

      def build_dependencies_hash(dependency_data)
        result = {}
        dependency_data.each do |class_name, dependencies|
          result[class_name] = []
          dependencies.each do |dep|
            if dep.is_a?(Hash)
              dep.each do |constant, _methods|
                result[class_name] << constant unless result[class_name].include?(constant)
              end
            end
          end
        end
        result
      end
    end
  end
end
