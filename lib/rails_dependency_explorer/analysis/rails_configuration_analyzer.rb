# frozen_string_literal: true

require_relative "analyzer_interface"

module RailsDependencyExplorer
  module Analysis
    # Analyzes Rails configuration dependencies and environment-specific code.
    # Detects Rails.application.config, Rails.env, environment variables, secrets,
    # and credentials access patterns to identify configuration dependencies.
    class RailsConfigurationAnalyzer
      include AnalyzerInterface
      def initialize(dependency_data)
        @dependency_data = dependency_data
      end

      # Implementation of AnalyzerInterface
      def analyze
        analyze_configuration_dependencies
      end

      def analyze_configuration_dependencies
        configuration_dependencies = {}

        @dependency_data.each do |class_name, dependencies|
          configuration_dependencies[class_name] = extract_configuration_for_class(dependencies)
        end

        configuration_dependencies
      end

      private

      def extract_configuration_for_class(dependencies)
        class_config = {
          rails_config: [],
          environment_variables: [],
          secrets_and_credentials: []
        }

        dependencies.each do |dep|
          next unless dep.is_a?(Hash)

          dep.each do |constant_name, methods|
            categorize_configuration_dependency(constant_name, methods, class_config)
          end
        end

        class_config
      end

      def categorize_configuration_dependency(constant_name, methods, class_config)
        case constant_name
        when "Rails"
          categorize_rails_methods(methods, class_config)
        when "ENV"
          add_unique_config_pattern(class_config[:environment_variables], "ENV")
        else
          # Ignore other constants for now
        end
      end

      def categorize_rails_methods(methods, class_config)
        methods.each do |method|
          rails_config_pattern = RAILS_CONFIG_PATTERNS[method]

          if rails_config_pattern
            add_unique_config_pattern(class_config[:rails_config], rails_config_pattern)
          end
        end
      end

      def add_unique_config_pattern(config_array, pattern)
        config_array << pattern unless config_array.include?(pattern)
      end

      # Maps Rails method names to their full configuration patterns
      RAILS_CONFIG_PATTERNS = {
        "logger" => "Rails.logger",
        "env" => "Rails.env",
        "application" => "Rails.application.config", # Most common usage
        "root" => "Rails.root",
        "cache" => "Rails.cache"
      }.freeze
    end
  end
end
