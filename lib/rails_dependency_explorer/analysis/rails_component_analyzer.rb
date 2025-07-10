# frozen_string_literal: true

module RailsDependencyExplorer
  module Analysis
    # Analyzes and categorizes Rails components based on class names and inheritance patterns.
    # Identifies models, controllers, services, and other Rails-specific component types
    # to provide better organization and understanding of Rails application structure.
    class RailsComponentAnalyzer
      def initialize(dependency_data)
        @dependency_data = dependency_data
      end

      def categorize_components
        components = {
          models: [],
          controllers: [],
          services: [],
          other: []
        }

        # Analyze defined classes
        @dependency_data.each do |class_name, dependencies|
          category = determine_component_type(class_name, dependencies)
          components[category] << class_name
        end

        # Analyze referenced dependencies
        all_referenced_classes = extract_all_referenced_classes
        all_referenced_classes.each do |class_name|
          next if components.values.flatten.include?(class_name) # Skip if already categorized

          category = determine_component_type_by_name(class_name)
          components[category] << class_name
        end

        components
      end

      private

      def determine_component_type(class_name, dependencies)
        # Check for Rails models (inherit from ApplicationRecord)
        return :models if inherits_from_application_record?(dependencies)
        
        # Check for Rails controllers (inherit from ApplicationController or end with Controller)
        return :controllers if rails_controller?(class_name, dependencies)
        
        # Check for service classes (end with Service)
        return :services if service_class?(class_name)
        
        # Everything else is categorized as other
        :other
      end

      def inherits_from_application_record?(dependencies)
        dependencies.any? do |dep|
          dep.is_a?(Hash) && dep.key?("ApplicationRecord")
        end
      end

      def rails_controller?(class_name, dependencies)
        inherits_from_application_controller?(dependencies) || controller_name_pattern?(class_name)
      end

      def inherits_from_application_controller?(dependencies)
        dependencies.any? do |dep|
          dep.is_a?(Hash) && dep.key?("ApplicationController")
        end
      end

      def controller_name_pattern?(class_name)
        class_name.end_with?("Controller")
      end

      def service_class?(class_name)
        class_name.end_with?("Service")
      end

      def extract_all_referenced_classes
        referenced_classes = []

        @dependency_data.each do |class_name, dependencies|
          dependencies.each do |dep|
            if dep.is_a?(Hash)
              referenced_classes.concat(dep.keys)
            end
          end
        end

        referenced_classes.uniq
      end

      def determine_component_type_by_name(class_name)
        # For referenced classes, we can only determine type by name patterns
        return :controllers if controller_name_pattern?(class_name)
        return :services if service_class?(class_name)
        return :models if rails_model_name?(class_name)

        :other
      end

      def rails_model_name?(class_name)
        # Common Rails model patterns - could be expanded
        %w[ApplicationRecord ActiveRecord].include?(class_name)
      end
    end
  end
end
