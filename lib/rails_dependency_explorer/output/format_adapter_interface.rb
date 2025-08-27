# frozen_string_literal: true

module RailsDependencyExplorer
  module Output
    # Common interface for all format adapters.
    # Provides a template method pattern for consistent formatting behavior
    # across different output formats (JSON, HTML, CSV, Console, DOT).
    # Part of A3: Extract Missing Abstractions to reduce duplication.
    module FormatAdapterInterface
      # Template method for formatting dependency data
      # Subclasses should implement format_content method
      # @param dependency_data [Hash] The dependency data to format
      # @param statistics [Hash] Optional statistics data
      # @return [String] Formatted output
      def format(dependency_data, statistics = {})
        validate_input(dependency_data)
        format_content(dependency_data, statistics)
      end

      # Abstract method to be implemented by concrete adapters
      # @param dependency_data [Hash] The dependency data to format
      # @param statistics [Hash] Optional statistics data
      # @return [String] Formatted output
      def format_content(dependency_data, statistics = {})
        raise NotImplementedError, "Subclasses must implement format_content method"
      end

      private

      # Common validation logic for all format adapters
      # @param dependency_data [Hash] The dependency data to validate
      def validate_input(dependency_data)
        raise ArgumentError, "dependency_data must be a Hash" unless dependency_data.is_a?(Hash)
      end

      # Common helper to extract unique dependencies from dependency data
      # @param dependency_data [Hash] The dependency data
      # @return [Hash] Simplified dependency mapping
      def extract_dependencies(dependency_data)
        simplified = {}
        
        dependency_data.each do |class_name, dependencies|
          unique_deps = Set.new
          
          dependencies.each do |dep_hash|
            dep_hash.each_key do |constant_name|
              unique_deps.add(constant_name)
            end
          end
          
          simplified[class_name] = unique_deps.to_a
        end
        
        simplified
      end

      # Common helper to check if dependency data is empty
      # @param dependency_data [Hash] The dependency data
      # @return [Boolean] True if no dependencies found
      def empty_dependencies?(dependency_data)
        dependency_data.empty? || dependency_data.values.all?(&:empty?)
      end

      # Common helper to extract nodes from dependency data
      # @param dependency_data [Hash] The dependency data
      # @return [Array<String>] List of all nodes (classes and dependencies)
      def extract_nodes(dependency_data)
        nodes = Set.new
        
        dependency_data.each do |class_name, dependencies|
          nodes.add(class_name)
          
          dependencies.each do |dep_hash|
            dep_hash.each_key do |constant_name|
              nodes.add(constant_name)
            end
          end
        end
        
        nodes.to_a
      end

      # Common helper to extract edges from dependency data
      # @param dependency_data [Hash] The dependency data
      # @return [Array<Array<String>>] List of edges as [source, target] pairs
      def extract_edges(dependency_data)
        edges = []
        
        dependency_data.each do |class_name, dependencies|
          dependencies.each do |dep_hash|
            dep_hash.each_key do |constant_name|
              edges << [class_name, constant_name]
            end
          end
        end
        
        edges
      end

      # Common helper to format statistics section
      # @param statistics [Hash] Statistics data
      # @return [String] Formatted statistics
      def format_statistics_section(statistics)
        return "" if statistics.empty?
        
        lines = []
        lines << "Statistics:"
        lines << "  Total Classes: #{statistics[:total_classes]}" if statistics[:total_classes]
        lines << "  Total Dependencies: #{statistics[:total_dependencies]}" if statistics[:total_dependencies]
        lines << "  Most Used Dependency: #{statistics[:most_used_dependency]}" if statistics[:most_used_dependency]
        
        lines.join("\n")
      end
    end
  end
end
