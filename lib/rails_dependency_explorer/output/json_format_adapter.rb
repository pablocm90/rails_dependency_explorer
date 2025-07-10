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
          "dependencies" => self.class.build_dependencies_hash(dependency_data),
          "statistics" => statistics
        }
        JSON.generate(json_data)
      end

      private

      def self.build_dependencies_hash(dependency_data)
        result = {}
        dependency_data.each do |class_name, dependencies|
          result[class_name] = extract_class_dependencies(dependencies)
        end
        result
      end

      def self.extract_class_dependencies(dependencies)
        class_dependencies = []
        dependencies.each do |dep|
          if dep.is_a?(Hash)
            dep.each do |constant, _methods|
              class_dependencies << constant unless class_dependencies.include?(constant)
            end
          end
        end
        class_dependencies
      end
    end
  end
end
