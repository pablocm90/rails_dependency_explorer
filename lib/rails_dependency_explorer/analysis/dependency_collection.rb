# frozen_string_literal: true

module RailsDependencyExplorer
  module Analysis
    # Collects and manages dependency relationships between classes and constants.
    # Provides methods to add method calls, merge hash dependencies, and convert
    # the collected data into various formats for analysis and visualization.
    class DependencyCollection
      def initialize
        @dependencies = {}
      end

      def add_method_call(constant_name, method_name)
        constant_dependencies = (@dependencies[constant_name] ||= [])
        constant_dependencies << method_name unless constant_dependencies.include?(method_name)
      end

      def add_constant_access(constant_name, accessed_constant)
        add_method_call(constant_name, accessed_constant)
      end

      def to_grouped_array
        @dependencies.map { |const_name, methods| {const_name => methods} }
      end

      def merge_hash_dependency(hash_dep)
        hash_dep.each do |const_name, methods|
          methods.each { |method| add_method_call(const_name, method) }
        end
      end
    end
  end
end
