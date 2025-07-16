# frozen_string_literal: true

module RailsDependencyExplorer
  module Analysis
    # Interface for analyzers that categorize and analyze components by type.
    # Provides common component classification utilities and relationship analysis.
    # Analyzers that work with Rails components (controllers, models, services) should include this interface.
    module ComponentAnalyzerInterface
      def self.included(base)
        # Module included callback - can be used for validation or setup
      end

      # Categorizes components by their type (controller, model, service, etc.)
      # @return [Hash] Hash with component types as keys and arrays of component names as values
      def categorize_components
        return empty_categories if @dependency_data.nil? || @dependency_data.empty?
        
        categories = { controllers: [], models: [], services: [], other: [] }
        
        @dependency_data.keys.each do |component_name|
          category = classify_component(component_name)
          # Map category to the correct key, defaulting to :other
          category_key = case category
                        when :controller then :controllers
                        when :model then :models
                        when :service then :services
                        else :other
                        end
          categories[category_key] << component_name
        end
        
        categories
      end

      # Classifies a single component by its name and characteristics
      # @param component_name [String] The name of the component to classify
      # @return [Symbol] The component type (:controller, :model, :service, :other)
      def classify_component(component_name)
        return :other if component_name.nil? || component_name.empty?
        
        case component_name
        when /Controller$/
          :controller
        when /Service$/
          :service
        when /^[A-Z][a-zA-Z]*$/ # Simple class name pattern
          # Check if it inherits from ActiveRecord patterns
          dependencies = @dependency_data[component_name] || []
          if dependencies.any? { |dep| dep.keys.any? { |k| k.include?('ActiveRecord') } }
            :model
          else
            :other
          end
        else
          :other
        end
      end

      # Analyzes relationships between different component types
      # @return [Hash] Hash describing relationships between component types
      def analyze_component_relationships
        return empty_relationships if @dependency_data.nil? || @dependency_data.empty?
        
        relationships = {
          controller_to_model: [],
          controller_to_service: [],
          service_to_model: [],
          service_to_service: [],
          model_to_model: [],
          other_relationships: []
        }
        
        @dependency_data.each do |component_name, dependencies|
          from_type = classify_component(component_name)
          
          dependencies.each do |dependency_hash|
            dependency_hash.keys.each do |dependency_name|
              to_type = classify_component(dependency_name)
              
              relationship_key = build_relationship_key(from_type, to_type)
              if relationships.key?(relationship_key)
                relationships[relationship_key] << [component_name, dependency_name]
              end
            end
          end
        end
        
        relationships
      end

      # Calculates metrics about component distribution and coupling
      # @return [Hash] Metrics including component counts, coupling by type, and layering violations
      def calculate_component_metrics
        return empty_metrics if @dependency_data.nil? || @dependency_data.empty?
        
        categories = categorize_components

        # Count components by type
        component_counts = {
          controllers: categories[:controllers].size,
          models: categories[:models].size,
          services: categories[:services].size,
          other: categories[:other].size
        }
        
        # Calculate coupling by component type
        coupling_by_type = calculate_coupling_by_type(categories)
        
        # Detect layering violations
        layering_violations = detect_layering_violations
        
        {
          component_counts: component_counts,
          coupling_by_type: coupling_by_type,
          layering_violations: layering_violations
        }
      end

      private

      # Returns empty categories for nil/empty data
      def empty_categories
        { controllers: [], models: [], services: [], other: [] }
      end

      # Returns empty relationships for nil/empty data
      def empty_relationships
        {
          controller_to_model: [],
          controller_to_service: [],
          service_to_model: [],
          service_to_service: [],
          model_to_model: [],
          other_relationships: []
        }
      end

      # Returns empty metrics for nil/empty data
      def empty_metrics
        {
          component_counts: { controllers: 0, models: 0, services: 0, other: 0 },
          coupling_by_type: { controllers: 0, models: 0, services: 0, other: 0 },
          layering_violations: []
        }
      end

      # Builds relationship key from component types
      def build_relationship_key(from_type, to_type)
        case [from_type, to_type]
        when [:controller, :model]
          :controller_to_model
        when [:controller, :service]
          :controller_to_service
        when [:service, :model]
          :service_to_model
        when [:service, :service]
          :service_to_service
        when [:model, :model]
          :model_to_model
        else
          :other_relationships
        end
      end

      # Calculates coupling metrics by component type
      def calculate_coupling_by_type(categories)
        coupling = { controllers: 0, models: 0, services: 0, other: 0 }
        
        categories.each do |type, components|
          total_dependencies = 0
          components.each do |component|
            dependencies = @dependency_data[component] || []
            total_dependencies += dependencies.size
          end
          
          coupling[type] = components.empty? ? 0 : (total_dependencies.to_f / components.size).round(2)
        end
        
        coupling
      end

      # Detects architectural layering violations
      def detect_layering_violations
        violations = []
        
        @dependency_data.each do |component_name, dependencies|
          from_type = classify_component(component_name)
          
          dependencies.each do |dependency_hash|
            dependency_hash.keys.each do |dependency_name|
              to_type = classify_component(dependency_name)
              
              # Check for violations (lower layers depending on higher layers)
              if violates_layering?(from_type, to_type)
                violations << {
                  from: component_name,
                  to: dependency_name,
                  from_type: from_type,
                  to_type: to_type,
                  violation_type: "#{from_type}_to_#{to_type}"
                }
              end
            end
          end
        end
        
        violations
      end

      # Checks if a dependency violates architectural layering
      def violates_layering?(from_type, to_type)
        # Define layer hierarchy (higher number = higher layer)
        layer_hierarchy = {
          controller: 3,
          service: 2,
          model: 1,
          other: 0
        }
        
        from_layer = layer_hierarchy[from_type] || 0
        to_layer = layer_hierarchy[to_type] || 0
        
        # Violation if lower layer depends on higher layer
        from_layer < to_layer
      end
    end
  end
end
