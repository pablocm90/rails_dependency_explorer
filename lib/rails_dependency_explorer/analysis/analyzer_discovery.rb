# frozen_string_literal: true

module RailsDependencyExplorer
  module Analysis
    # Discovers analyzer classes that implement AnalyzerInterface.
    # Provides automatic discovery and metadata extraction for pluggable analyzer system.
    # Part of Phase 3.2 pluggable analyzer system implementation.
    class AnalyzerDiscovery
      def initialize(namespace: "RailsDependencyExplorer::Analysis", plugin_interface: nil)
        @namespace = namespace
        @plugin_interface = plugin_interface
      end

      # Discover all analyzer classes implementing AnalyzerInterface
      def discover_analyzers(category: nil)
        # Discover built-in analyzers
        analyzer_classes = find_analyzer_classes
        result = {}

        analyzer_classes.each do |analyzer_class|
          key = class_name_to_key(analyzer_class.name)

          # Filter by category if specified
          if category
            metadata = extract_metadata(analyzer_class)
            next unless metadata[:category] == category
          end

          result[key] = analyzer_class
        end

        # Add plugin analyzers if plugin interface is available
        if @plugin_interface
          plugin_analyzers = @plugin_interface.registered_plugins
          plugin_analyzers.each do |key, analyzer_class|
            # Filter by category if specified
            if category
              metadata = extract_metadata(analyzer_class)
              next unless metadata[:category] == category
            end

            result[key] = analyzer_class
          end
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
        klass.ancestors.include?(RailsDependencyExplorer::Analysis::AnalyzerInterface)
      rescue NameError
        false
      end

      # Convert class name to snake_case key
      def class_name_to_key(class_name)
        # Extract just the class name without module path
        simple_name = class_name.split('::').last
        
        # Convert to snake_case
        snake_case = simple_name
          .gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
          .gsub(/([a-z\d])([A-Z])/, '\1_\2')
          .downcase
        
        snake_case.to_sym
      end

      # Extract metadata from analyzer class
      def extract_metadata(analyzer_class)
        metadata = {
          description: extract_description(analyzer_class),
          category: extract_category(analyzer_class)
        }
        
        metadata
      end

      # Extract description from class documentation
      def extract_description(analyzer_class)
        class_name = get_simple_class_name(analyzer_class)

        ANALYZER_DESCRIPTIONS.each do |pattern, description|
          return description if class_name.match?(pattern)
        end

        # Default description
        "Analyzer for #{class_name.gsub(/([A-Z])/, ' \1').strip.downcase}"
      end

      # Extract category from analyzer class
      def extract_category(analyzer_class)
        class_name = get_simple_class_name(analyzer_class)

        ANALYZER_CATEGORIES.each do |pattern, category|
          return category if class_name.match?(pattern)
        end

        :general
      end

      # Get simple class name without module path
      def get_simple_class_name(analyzer_class)
        analyzer_class.name.split('::').last
      end

      # Analyzer description patterns
      ANALYZER_DESCRIPTIONS = {
        /Circular/i => "Detects circular dependencies in code",
        /Depth/i => "Calculates dependency depth for classes",
        /Statistics/i => "Calculates statistical metrics for dependencies",
        /Rails.*Component/i => "Analyzes and categorizes Rails components",
        /ActiveRecord.*Relationship/i => "Analyzes ActiveRecord relationships and associations"
      }.freeze

      # Analyzer category patterns
      ANALYZER_CATEGORIES = {
        /Circular|Depth/i => :dependency_analysis,
        /Statistics/i => :metrics,
        /Rails|Component/i => :rails_analysis,
        /ActiveRecord/i => :activerecord_analysis
      }.freeze
    end
  end
end
