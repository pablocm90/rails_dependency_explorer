# frozen_string_literal: true

module RailsDependencyExplorer
  module Parsing
    # Utility methods for dependency parsing operations.
    # Provides static helper methods for class name extraction and
    # dependency accumulation, supporting the dependency parsing workflow.
    class DependencyParserUtils
      def self.extract_class_name(ast)
        class_name_node = ast.children.first
        return "" unless class_name_node&.children&.[](1)

        class_name_node.children[1].to_s
      end

      def self.accumulate_visited_dependencies(dependencies, accumulator)
        dependencies = [dependencies] unless dependencies.is_a?(Array)
        dependencies.flatten.each do |dep|
          if dep.is_a?(Hash)
            accumulator.record_hash_dependency(dep)
          elsif dep.is_a?(String)
            # Handle plain string constants (e.g., class inheritance like "ApplicationRecord")
            # Creates {"ConstantName" => [[]]} to maintain compatibility with Rails component detection
            accumulator.record_method_call(dep, [])
          end
        end
      end
    end
  end
end
