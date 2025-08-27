# frozen_string_literal: true

require_relative "../interfaces/analyzer_interface"

module RailsDependencyExplorer
  module Analysis
    module Analyzers
      # Analyzes Rails configuration dependencies and environment-specific code.
      # Detects Rails.application.config, Rails.env, environment variables, secrets,
      # and credentials access patterns to identify configuration dependencies.
      class RailsConfigurationAnalyzer
        include Interfaces::AnalyzerInterface
        
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

            dep.each do |constant, methods|
              case constant
              when "Rails"
                rails_methods = methods.map do |method|
                  case method
                  when "application"
                    "Rails.application.config"
                  else
                    "Rails.#{method}"
                  end
                end
                class_config[:rails_config].concat(rails_methods)
              when "ENV"
                class_config[:environment_variables] << constant
              end
            end
          end

          # Remove duplicates while preserving order
          class_config[:rails_config] = class_config[:rails_config].uniq
          class_config[:environment_variables] = class_config[:environment_variables].uniq
          class_config[:secrets_and_credentials] = class_config[:secrets_and_credentials].uniq

          class_config
        end
      end
    end
  end
end
