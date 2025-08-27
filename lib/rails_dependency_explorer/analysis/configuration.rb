# frozen_string_literal: true

# Configuration module - Contains configuration and discovery classes
# Part of structural reorganization to improve codebase organization

require_relative "configuration/analyzer_configuration"
require_relative "configuration/analyzer_discovery"
require_relative "configuration/dependency_container"
require_relative "configuration/dependency_collection"

module RailsDependencyExplorer
  module Analysis
    # Namespace for configuration and discovery classes
    # Contains classes that handle analyzer configuration and discovery
    module Configuration
      # This module contains all configuration and discovery classes
    end
  end
end
