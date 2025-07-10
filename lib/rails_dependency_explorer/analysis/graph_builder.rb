module RailsDependencyExplorer
  module Analysis
    # Utility class for building graph data structures from dependency data
    class GraphBuilder
      # Builds an adjacency list representation from dependency data
      #
      # @param dependency_data [Hash] Hash where keys are class names and values are arrays of dependencies
      # @return [Hash] Adjacency list where keys are class names and values are arrays of dependent class names
      def self.build_adjacency_list(dependency_data)
        graph = Hash.new { |h, k| h[k] = [] }
        populate_graph_from_dependencies(dependency_data, graph)
        graph
      end

      private

      def self.populate_graph_from_dependencies(dependency_data, graph)
        dependency_data.each do |class_name, dependencies|
          dependencies.each do |dep|
            add_hash_dependencies_to_graph(class_name, dep, graph) if dep.is_a?(Hash)
          end
        end
      end

      def self.add_hash_dependencies_to_graph(class_name, dep, graph)
        class_dependencies = graph[class_name]
        dep.each do |constant, methods|
          class_dependencies << constant unless class_dependencies.include?(constant)
        end
      end
    end
  end
end
