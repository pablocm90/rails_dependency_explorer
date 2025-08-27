# frozen_string_literal: true

require_relative 'analyzer_interface'

module RailsDependencyExplorer
  module Analysis
    module Interfaces
      # Plugin interface for registering and managing custom analyzer plugins.
    # Enables dynamic loading of external analyzers and extends the discovery system.
    # Part of Phase 3.2.3 plugin interface implementation.
    class AnalyzerPluginInterface
      def initialize
        @registered_plugins = {}
      end

      # Register a custom analyzer plugin
      def register_plugin(key, analyzer_class)
        validate_plugin(analyzer_class)
        @registered_plugins[key] = analyzer_class
      end

      # Unregister a plugin
      def unregister_plugin(key)
        @registered_plugins.delete(key)
      end

      # Get all registered plugins
      def registered_plugins
        @registered_plugins.dup
      end

      # List all plugins with metadata
      def list_plugins
        @registered_plugins.map do |key, analyzer_class|
          {
            key: key,
            class: analyzer_class,
            name: analyzer_class.name
          }
        end
      end

      # Load plugin from file
      def load_plugin_from_file(file_path, plugin_key)
        analyzer_class = load_and_find_analyzer_class(file_path)

        if analyzer_class
          register_plugin(plugin_key, analyzer_class)
        else
          raise ArgumentError, "No valid analyzer class found in plugin file #{file_path}"
        end
      end

      # Discover plugins in a directory
      def discover_plugins_in_directory(directory_path)
        return {} unless Dir.exist?(directory_path)

        discovered_plugins = {}
        plugin_files = Dir.glob(File.join(directory_path, "*.rb"))

        plugin_files.each do |plugin_file|
          analyzer_classes = load_and_find_all_analyzer_classes(plugin_file)

          analyzer_classes.each do |analyzer_class|
            plugin_key = convert_class_name_to_key(analyzer_class.name)
            discovered_plugins[plugin_key] = analyzer_class
            register_plugin(plugin_key, analyzer_class)
          end
        end

        discovered_plugins
      end

      private

      # Load file and find the first analyzer class
      def load_and_find_analyzer_class(file_path)
        analyzer_classes = load_and_find_all_analyzer_classes(file_path)
        analyzer_classes.first
      end

      # Load file and find all analyzer classes
      def load_and_find_all_analyzer_classes(file_path)
        return [] unless File.exist?(file_path)

        # Store current constants to detect new ones
        before_constants = Object.constants

        begin
          # Load the plugin file
          load(file_path)

          # Find newly defined constants
          after_constants = Object.constants
          new_constants = after_constants - before_constants

          # Find analyzer classes among new constants
          analyzer_classes = []
          new_constants.each do |const_name|
            begin
              const = Object.const_get(const_name)

              if const.is_a?(Class) && implements_analyzer_interface?(const)
                analyzer_classes << const
              end
            rescue NameError
              # Class not found, skip
              next
            end
          end

          analyzer_classes
        rescue
          # Skip files that can't be loaded
          []
        end
      end

      # Validate that plugin implements AnalyzerInterface
      def validate_plugin(analyzer_class)
        unless implements_analyzer_interface?(analyzer_class)
          raise ArgumentError, "Plugin #{analyzer_class.name} must implement AnalyzerInterface"
        end
      end

      # Check if class implements AnalyzerInterface
      def implements_analyzer_interface?(analyzer_class)
        return false unless analyzer_class.is_a?(Class)
        
        analyzer_class.ancestors.include?(AnalyzerInterface)
      end

      # Convert CamelCase class name to snake_case key
      def convert_class_name_to_key(class_name)
        class_name
          .gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
          .gsub(/([a-z\d])([A-Z])/, '\1_\2')
          .downcase
          .to_sym
      end
    end
    end
  end
end
