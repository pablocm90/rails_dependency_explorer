# frozen_string_literal: true

module RailsDependencyExplorer
  module Analysis
    module Interfaces
      # Interface for analyzers that categorize and analyze components by type.
    # Provides common component classification utilities and relationship analysis.
    # Analyzers that work with Rails components (controllers, models, services) should include this interface.
    module ComponentAnalyzerInterface
      def self.included(base)
        # Module included callback - can be used for validation or setup
      end

      # Categorizes components by their type (controller, model, service, etc.)
      # @return [Hash] Hash with component types as keys and arrays of component names as values
      def classify_components
        return empty_categories if @dependency_data.nil? || @dependency_data.empty?

        categories = { controllers: [], models: [], services: [], other: [] }

        # Analyze defined classes (keys in dependency_data)
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

        # Analyze referenced dependencies (like existing analyzer does)
        all_referenced_classes = extract_all_referenced_classes
        all_referenced_classes.each do |class_name|
          next if categories.values.flatten.include?(class_name) # Skip if already categorized

          category = classify_component_by_name(class_name)
          # Map category to the correct key, defaulting to :other
          category_key = case category
                        when :controller then :controllers
                        when :model then :models
                        when :service then :services
                        else :other
                        end
          categories[category_key] << class_name
        end

        categories
      end

      # Alias for backward compatibility with existing tests
      alias_method :categorize_components, :classify_components

      # Classifies a single component by its name and characteristics
      # @param component_name [String] The name of the component to classify
      # @return [Symbol] The component type (:controller, :model, :service, :other)
      def classify_component(component_name)
        return :other if component_name.nil? || component_name.empty?

        dependencies = @dependency_data[component_name] || []

        # Use the same logic as RailsComponentAnalyzer
        # Check for Rails models (inherit from ApplicationRecord)
        return :model if inherits_from_application_record?(dependencies)

        # Check for Rails controllers (inherit from ApplicationController or end with Controller)
        return :controller if rails_controller?(component_name, dependencies)

        # Check for service classes (end with Service)
        return :service if service_class?(component_name)

        # Everything else is categorized as other
        :other
      end

      # Analyzes relationships between different component types
      # @return [Hash] Hash describing relationships between component types
      def analyze_component_relationships
        return empty_relationships if @dependency_data.nil? || @dependency_data.empty?

        relationships = initialize_relationships_structure
        populate_relationships(relationships)
        relationships
      end

      # Detects architectural layering violations
      # @return [Hash] Hash with violations_found, violation_details, and severity_levels
      def detect_layering_violations
        return empty_violation_result if @dependency_data.nil? || @dependency_data.empty?

        violations = find_layering_violations

        {
          violations_found: violations,
          violation_details: build_violation_details(violations),
          severity_levels: categorize_violation_severity(violations)
        }
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
        layering_violations = find_layering_violations
        
        {
          component_counts: component_counts,
          coupling_by_type: coupling_by_type,
          layering_violations: layering_violations
        }
      end

      private

      # Initialize the relationships data structure
      def initialize_relationships_structure
        {
          controller_to_model: {},
          controller_to_service: {},
          service_to_model: {},
          service_to_service: {},
          model_to_model: {},
          other_relationships: {},
          cross_layer_dependencies: []
        }
      end

      # Populate relationships by analyzing dependency data
      def populate_relationships(relationships)
        @dependency_data.each do |component_name, dependencies|
          from_type = classify_component(component_name)
          process_component_dependencies(relationships, component_name, from_type, dependencies)
        end
      end

      # Process dependencies for a single component
      def process_component_dependencies(relationships, component_name, from_type, dependencies)
        dependencies.each do |dependency_hash|
          dependency_hash.keys.each do |dependency_name|
            to_type = classify_component(dependency_name)
            add_relationship(relationships, component_name, from_type, dependency_name, to_type)
          end
        end
      end

      # Add a single relationship to the relationships structure
      def add_relationship(relationships, component_name, from_type, dependency_name, to_type)
        relationship_key = build_relationship_key(from_type, to_type)

        # Add to appropriate relationship category
        if relationships.key?(relationship_key) && relationship_key != :cross_layer_dependencies
          relationships[relationship_key][component_name] ||= []
          relationships[relationship_key][component_name] << dependency_name
        end

        # Track cross-layer dependencies
        if violates_layering?(from_type, to_type)
          relationships[:cross_layer_dependencies] << {
            source: component_name,
            target: dependency_name,
            relationship_type: "#{from_type}_to_#{to_type}"
          }
        end
      end

      # Returns empty categories for nil/empty data
      def empty_categories
        { controllers: [], models: [], services: [], other: [] }
      end

      # Returns empty relationships for nil/empty data
      def empty_relationships
        {
          controller_to_model: {},
          controller_to_service: {},
          service_to_model: {},
          service_to_service: {},
          model_to_model: {},
          other_relationships: {},
          cross_layer_dependencies: []
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

      # Returns empty violation result for nil/empty data
      def empty_violation_result
        {
          violations_found: [],
          violation_details: {},
          severity_levels: {}
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

      # Finds architectural layering violations (internal method)
      def find_layering_violations
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

      # Builds detailed violation information
      def build_violation_details(violations)
        details = {}
        violations.each do |violation|
          key = "#{violation[:from]}_to_#{violation[:to]}"
          details[key] = {
            description: "#{violation[:from_type]} '#{violation[:from]}' depends on #{violation[:to_type]} '#{violation[:to]}'",
            severity: determine_violation_severity(violation[:from_type], violation[:to_type])
          }
        end
        details
      end

      # Categorizes violations by severity level
      def categorize_violation_severity(violations)
        severity_levels = { high: [], medium: [], low: [] }
        violations.each do |violation|
          severity = determine_violation_severity(violation[:from_type], violation[:to_type])
          severity_levels[severity] << violation
        end
        severity_levels
      end

      # Determines severity of a specific violation
      def determine_violation_severity(from_type, to_type)
        case [from_type, to_type]
        when [:model, :controller]
          :high  # Models should never depend on controllers
        when [:service, :controller]
          :medium  # Services depending on controllers is questionable
        else
          :low
        end
      end

      # Check if class inherits from ApplicationRecord or ActiveRecord::Base (Rails model pattern)
      def inherits_from_application_record?(dependencies)
        dependencies.any? do |dependency_hash|
          dependency_hash.keys.any? { |key| key.include?('ApplicationRecord') || key.include?('ActiveRecord::Base') }
        end
      end

      # Check if class is a Rails controller
      def rails_controller?(class_name, dependencies)
        return true if class_name.end_with?('Controller')

        dependencies.any? do |dependency_hash|
          dependency_hash.keys.any? { |key| key.include?('ApplicationController') }
        end
      end

      # Check if class is a service class
      def service_class?(class_name)
        class_name.end_with?('Service')
      end

      # Extract all referenced classes from dependency data
      def extract_all_referenced_classes
        referenced_classes = []

        @dependency_data.each_value do |dependencies|
          dependencies.each do |dependency_hash|
            referenced_classes.concat(dependency_hash.keys)
          end
        end

        referenced_classes.uniq
      end

      # Classify component by name only (for referenced classes)
      def classify_component_by_name(class_name)
        return :other if class_name.nil? || class_name.empty?

        # For referenced classes, we can only determine type by name patterns
        return :controller if class_name.end_with?('Controller')
        return :service if class_name.end_with?('Service')
        return :model if rails_model_name?(class_name)

        :other
      end

      # Check if class name matches Rails model patterns
      def rails_model_name?(class_name)
        # Common Rails model patterns - could be expanded
        %w[ApplicationRecord ActiveRecord ActiveRecord::Base].include?(class_name)
      end
    end
    end
  end
end
