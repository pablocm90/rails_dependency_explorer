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

        dependency_data.each do |class_name, dependencies|
          dependencies.each do |dep|
            if dep.is_a?(Hash)
              dep.each do |constant, methods|
                graph[class_name] << constant unless graph[class_name].include?(constant)
              end
            end
          end
        end

        graph
      end
    end
  end
end
