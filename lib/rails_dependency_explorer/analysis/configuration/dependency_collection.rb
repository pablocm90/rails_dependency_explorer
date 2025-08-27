# frozen_string_literal: true

module RailsDependencyExplorer
  module Analysis
    module Configuration
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

        def merge_hash_dependency(hash_dependency)
          hash_dependency.each do |constant, methods|
            Array(methods).each do |method|
              add_method_call(constant, method)
            end
          end
        end

        def to_grouped_array
          @dependencies.map do |constant, methods|
            { constant => methods }
          end
        end

        def to_hash
          @dependencies.dup
        end

        def empty?
          @dependencies.empty?
        end

        def size
          @dependencies.size
        end

        def constants
          @dependencies.keys
        end

        def methods_for(constant)
          @dependencies[constant] || []
        end

        def clear
          @dependencies.clear
        end
      end
    end
  end
end
