# frozen_string_literal: true

# Analyzers module - Contains all analyzer implementation classes
# Part of structural reorganization to improve codebase organization

require_relative "analyzers/rails_configuration_analyzer"
require_relative "analyzers/circular_dependency_analyzer"
require_relative "analyzers/dependency_depth_analyzer"
require_relative "analyzers/dependency_statistics_calculator"
require_relative "analyzers/rails_component_analyzer"
require_relative "analyzers/activerecord_relationship_analyzer"

module RailsDependencyExplorer
  module Analysis
    # Namespace for all analyzer implementation classes
    # Contains concrete analyzers that perform specific types of dependency analysis
    module Analyzers
      # This module contains all analyzer implementations
    end
  end
end
