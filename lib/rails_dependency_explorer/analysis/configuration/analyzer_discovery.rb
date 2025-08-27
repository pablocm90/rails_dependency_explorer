# frozen_string_literal: true

module RailsDependencyExplorer
  module Analysis
    module Configuration
      # Discovers analyzer classes that implement AnalyzerInterface.
      # Provides automatic discovery and metadata extraction for pluggable analyzer system.
      # Part of Phase 3.2 pluggable analyzer system implementation.
      class AnalyzerDiscovery
        def initialize(namespace: "RailsDependencyExplorer::Analysis::Analyzers", plugin_interface: nil)
          @namespace = namespace
          @plugin_interface = plugin_interface
        end

        # Discover all analyzer classes
        def discover_analyzers(category: nil)
          # Discover built-in analyzers
          analyzer_classes = find_analyzer_classes
          result = {}

          analyzer_classes.each do |analyzer_class|
            key = class_name_to_key(analyzer_class.name)
            result[key] = analyzer_class
          end

          # Add plugin analyzers if plugin interface is available
          if @plugin_interface
            plugin_analyzers = @plugin_interface.registered_plugins
            result.merge!(plugin_analyzers)
          end

          # Filter by category if specified
          if category
            result = filter_by_category(result, category)
          end

          result
        end

        # Discover analyzers with their metadata
        def discover_analyzers_with_metadata
          # Discover built-in analyzers
          analyzer_classes = find_analyzer_classes
          result = {}

          analyzer_classes.each do |analyzer_class|
            key = class_name_to_key(analyzer_class.name)
            result[key] = {
              class: analyzer_class,
              metadata: extract_metadata(analyzer_class)
            }
          end

          # Add plugin analyzers if plugin interface is available
          if @plugin_interface
            plugin_analyzers = @plugin_interface.registered_plugins
            plugin_analyzers.each do |key, analyzer_class|
              result[key] = {
                class: analyzer_class,
                metadata: extract_metadata(analyzer_class)
              }
            end
          end

          result
        end

        private

        # Find all classes in the namespace that include AnalyzerInterface
        def find_analyzer_classes
          return [] unless namespace_exists?
          
          namespace_module = Object.const_get(@namespace)
          analyzer_classes = []
          
          namespace_module.constants.each do |const_name|
            const = namespace_module.const_get(const_name)
            
            # Check if it's a class that includes AnalyzerInterface
            if const.is_a?(Class) && includes_analyzer_interface?(const)
              analyzer_classes << const
            end
          end
          
          analyzer_classes
        end

        # Check if namespace exists
        def namespace_exists?
          Object.const_defined?(@namespace)
        rescue NameError
          false
        end

        # Check if class includes AnalyzerInterface
        def includes_analyzer_interface?(klass)
          # Check if class actually includes the AnalyzerInterface module
          klass.included_modules.any? { |mod| mod.name&.include?('AnalyzerInterface') }
        rescue
          false
        end

        # Filter analyzers by category
        def filter_by_category(analyzers, category)
          filtered = {}

          analyzers.each do |key, analyzer_class|
            analyzer_category = extract_category(analyzer_class)
            if analyzer_category == category
              filtered[key] = analyzer_class
            end
          end

          filtered
        end

        # Convert class name to analyzer key
        def class_name_to_key(class_name)
          # Extract just the class name without module path
          simple_name = class_name.split('::').last
          
          # Convert CamelCase to snake_case
          simple_name.gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
                     .gsub(/([a-z\d])([A-Z])/, '\1_\2')
                     .downcase
                     .to_sym
        end

        # Extract metadata from analyzer class
        def extract_metadata(analyzer_class)
          {
            name: analyzer_class.name,
            description: extract_description(analyzer_class),
            category: extract_category(analyzer_class)
          }
        end

        # Extract description from analyzer class
        def extract_description(analyzer_class)
          class_name = analyzer_class.name.split('::').last
          
          ANALYZER_DESCRIPTIONS.each do |pattern, description|
            return description if class_name.match?(pattern)
          end
          
          "Analyzer for #{class_name}"
        end

        # Extract category from analyzer class
        def extract_category(analyzer_class)
          class_name = analyzer_class.name.split('::').last
          
          ANALYZER_CATEGORIES.each do |pattern, category|
            return category if class_name.match?(pattern)
          end
          
          :other
        end

        # Analyzer description patterns
        ANALYZER_DESCRIPTIONS = {
          /Circular/i => "Detects circular dependencies in code",
          /Depth/i => "Calculates dependency depth for classes",
          /Statistics/i => "Calculates statistical metrics for dependencies",
          /Rails.*Component/i => "Analyzes and categorizes Rails components",
          /ActiveRecord.*Relationship/i => "Analyzes ActiveRecord relationships and associations",
          /Metadata.*Test/i => "metadata test analyzer"
        }.freeze

        # Analyzer category patterns
        ANALYZER_CATEGORIES = {
          /Circular|Depth/i => :dependency_analysis,
          /Statistics/i => :metrics,
          /Rails|Component/i => :rails_analysis,
          /ActiveRecord/i => :activerecord_analysis,
          /Test|Metadata/i => :general
        }.freeze
      end
    end
  end
end
