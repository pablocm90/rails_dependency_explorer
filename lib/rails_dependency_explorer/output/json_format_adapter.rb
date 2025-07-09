# frozen_string_literal: true

require "json"

module RailsDependencyExplorer
  module Output
    # Formats dependency analysis results into JSON format for programmatic consumption.
    # Converts dependency data into structured JSON with optional statistics,
    # suitable for API responses, data exchange, and further processing.
    class JsonFormatAdapter
      def format(dependency_data, statistics = nil)
        json_data = {
          "dependencies" => build_dependencies_hash(dependency_data),
          "statistics" => statistics
        }
        JSON.generate(json_data)
      end

      private

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
