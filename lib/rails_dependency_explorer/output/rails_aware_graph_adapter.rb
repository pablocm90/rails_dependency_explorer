# frozen_string_literal: true

require "set"

module RailsDependencyExplorer
  module Output
    # Enhanced graph adapter that handles ActiveRecord relationships intelligently.
    # Transforms ActiveRecord relationship data into meaningful model-to-model connections
    # while preserving regular code dependencies, creating more useful visualizations for Rails applications.
    class RailsAwareGraphAdapter
      def to_graph(dependency_data)
        nodes = extract_nodes(dependency_data)
        edges = extract_edges(dependency_data)

        {
          nodes: nodes.to_a,
          edges: edges.to_a
        }
      end

      private

      def extract_nodes(dependency_data)
        nodes = Set.new

        dependency_data.each do |class_name, dependencies|
          nodes.add(class_name)
          add_regular_dependency_nodes(nodes, dependencies)
          add_activerecord_target_nodes(nodes, dependencies)
        end

        nodes
      end

      def add_regular_dependency_nodes(nodes, dependencies)
        dependencies.each do |dependency_hash|
          dependency_hash.each do |constant_name, _methods|
            # Skip ActiveRecord relationship methods - we'll handle these separately
            next if activerecord_relationship?(constant_name)

            nodes.add(constant_name)
          end
        end
      end

      def add_activerecord_target_nodes(nodes, dependencies)
        dependencies.each do |dependency_hash|
          dependency_hash.each do |constant_name, target_models|
            if activerecord_relationship?(constant_name)
              target_models.each { |target_model| nodes.add(target_model) }
            end
          end
        end
      end

      def extract_edges(dependency_data)
        edges = Set.new

        dependency_data.each do |class_name, dependencies|
          add_regular_dependency_edges(edges, class_name, dependencies)
          add_activerecord_relationship_edges(edges, class_name, dependencies)
        end

        edges
      end

      def add_regular_dependency_edges(edges, class_name, dependencies)
        dependencies.each do |dependency_hash|
          dependency_hash.each do |constant_name, _methods|
            # Skip ActiveRecord relationship methods - we'll handle these separately
            next if activerecord_relationship?(constant_name)

            edges.add([class_name, constant_name])
          end
        end
      end

      def add_activerecord_relationship_edges(edges, class_name, dependencies)
        dependencies.each do |dependency_hash|
          dependency_hash.each do |constant_name, target_models|
            if activerecord_relationship?(constant_name)
              target_models.each do |target_model|
                edges.add([class_name, target_model])
              end
            end
          end
        end
      end

      def activerecord_relationship?(constant_name)
        constant_name.start_with?("ActiveRecord::")
      end
    end
  end
end
