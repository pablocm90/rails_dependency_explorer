# frozen_string_literal: true

require "set"
require "json"
require_relative "dependency_graph_adapter"

module RailsDependencyExplorer
  module Output
    class DependencyVisualizer
      def to_graph(dependency_data)
        graph_adapter.to_graph(dependency_data)
      end

      def to_dot(dependency_data)
        graph = to_graph(dependency_data)
        format_as_dot(graph[:edges])
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

      def format_as_dot(edges)
        dot_content = edges.map { |edge| "  \"#{edge[0]}\" -> \"#{edge[1]}\";" }.join("\n")
        "digraph dependencies {\n#{dot_content}\n}"
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
