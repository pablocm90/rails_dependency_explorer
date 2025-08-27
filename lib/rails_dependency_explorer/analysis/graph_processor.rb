# frozen_string_literal: true

require "set"

module RailsDependencyExplorer
  module Analysis
    # Common graph processing functionality for dependency analysis.
    # Provides shared methods for extracting nodes, edges, and processing dependency data
    # that are used across multiple analyzers and adapters.
    # Part of A3: Extract Missing Abstractions to reduce duplication.
    class GraphProcessor
      # Extract all unique nodes from dependency data
      # @param dependency_data [Hash] The dependency data
      # @return [Set<String>] Set of all node names
      def self.extract_nodes(dependency_data)
        nodes = Set.new
        
        dependency_data.each do |class_name, dependencies|
          nodes.add(class_name)
          add_dependency_nodes(nodes, dependencies)
        end
        
        nodes
      end

      # Extract all edges from dependency data
      # @param dependency_data [Hash] The dependency data
      # @return [Set<Array<String>>] Set of edges as [source, target] pairs
      def self.extract_edges(dependency_data)
        edges = Set.new
        
        dependency_data.each do |class_name, dependencies|
          add_dependency_edges(edges, class_name, dependencies)
        end
        
        edges
      end

      # Build adjacency list representation of the dependency graph
      # @param dependency_data [Hash] The dependency data
      # @return [Hash<String, Array<String>>] Adjacency list
      def self.build_adjacency_list(dependency_data)
        adjacency_list = {}
        
        dependency_data.each do |class_name, dependencies|
          adjacency_list[class_name] ||= []
          
          dependencies.each do |dependency_hash|
            dependency_hash.each_key do |constant_name|
              # Skip ActiveRecord relationships for graph traversal
              next if activerecord_relationship?(constant_name)
              
              adjacency_list[class_name] << constant_name
              adjacency_list[constant_name] ||= []
            end
          end
        end
        
        adjacency_list
      end

      # Convert dependency data to simple graph structure
      # @param dependency_data [Hash] The dependency data
      # @return [Hash] Graph with :nodes and :edges keys
      def self.to_graph(dependency_data)
        nodes = extract_nodes(dependency_data)
        edges = extract_edges(dependency_data)
        
        {
          nodes: nodes.to_a,
          edges: edges.to_a
        }
      end

      # Filter dependency data by predicate
      # @param dependency_data [Hash] The dependency data
      # @param predicate [Proc] Block that takes (class_name, constant_name) and returns boolean
      # @return [Hash] Filtered dependency data
      def self.filter_dependencies(dependency_data, &predicate)
        filtered = {}
        
        dependency_data.each do |class_name, dependencies|
          filtered_deps = []
          
          dependencies.each do |dependency_hash|
            filtered_hash = {}
            
            dependency_hash.each do |constant_name, methods|
              if predicate.call(class_name, constant_name)
                filtered_hash[constant_name] = methods
              end
            end
            
            filtered_deps << filtered_hash unless filtered_hash.empty?
          end
          
          filtered[class_name] = filtered_deps unless filtered_deps.empty?
        end
        
        filtered
      end

      # Get all dependencies for a specific class
      # @param dependency_data [Hash] The dependency data
      # @param class_name [String] The class name to get dependencies for
      # @return [Array<String>] List of dependency names
      def self.dependencies_for_class(dependency_data, class_name)
        dependencies = dependency_data[class_name] || []
        unique_deps = Set.new
        
        dependencies.each do |dependency_hash|
          dependency_hash.each_key do |constant_name|
            unique_deps.add(constant_name)
          end
        end
        
        unique_deps.to_a
      end

      # Count total dependencies in the data
      # @param dependency_data [Hash] The dependency data
      # @return [Integer] Total number of unique dependencies
      def self.count_total_dependencies(dependency_data)
        all_deps = Set.new
        
        dependency_data.each_value do |dependencies|
          dependencies.each do |dependency_hash|
            dependency_hash.each_key do |constant_name|
              all_deps.add(constant_name)
            end
          end
        end
        
        all_deps.size
      end

      # Find most frequently used dependency
      # @param dependency_data [Hash] The dependency data
      # @return [String, nil] Most used dependency name or nil if empty
      def self.most_used_dependency(dependency_data)
        dependency_counts = Hash.new(0)
        
        dependency_data.each_value do |dependencies|
          dependencies.each do |dependency_hash|
            dependency_hash.each_key do |constant_name|
              dependency_counts[constant_name] += 1
            end
          end
        end
        
        return nil if dependency_counts.empty?
        
        dependency_counts.max_by { |_name, count| count }&.first
      end

      private

      # Add dependency nodes to the nodes set
      # @param nodes [Set] The nodes set to add to
      # @param dependencies [Array] The dependencies array
      def self.add_dependency_nodes(nodes, dependencies)
        dependencies.each do |dependency_hash|
          dependency_hash.each_key do |constant_name|
            nodes.add(constant_name)
          end
        end
      end

      # Add dependency edges to the edges set
      # @param edges [Set] The edges set to add to
      # @param class_name [String] The source class name
      # @param dependencies [Array] The dependencies array
      def self.add_dependency_edges(edges, class_name, dependencies)
        dependencies.each do |dependency_hash|
          dependency_hash.each_key do |constant_name|
            edges.add([class_name, constant_name])
          end
        end
      end

      # Check if a constant name represents an ActiveRecord relationship
      # @param constant_name [String] The constant name to check
      # @return [Boolean] True if it's an ActiveRecord relationship
      def self.activerecord_relationship?(constant_name)
        constant_name.to_s.start_with?("ActiveRecord::")
      end
    end
  end
end
