# frozen_string_literal: true

# Rails Dependency Explorer - A comprehensive tool for analyzing dependencies in Ruby/Rails applications.
# Provides dependency analysis, circular dependency detection, Rails component categorization,
# ActiveRecord relationship analysis, and multiple output formats for visualization and reporting.
#
# The gem is organized into four main modules:
# - Analysis: Core dependency analysis and coordination
# - Parsing: Ruby code parsing and AST processing
# - Output: Multiple format adapters for visualization
# - CLI: Command-line interface and user interaction
# - Utils: Utility classes organized by functional area

require_relative "rails_dependency_explorer/version"
# Load organized analysis modules (new structure)
require_relative "rails_dependency_explorer/analysis/interfaces"
require_relative "rails_dependency_explorer/analysis/state"
require_relative "rails_dependency_explorer/analysis/utilities"
require_relative "rails_dependency_explorer/analysis/analyzers"
require_relative "rails_dependency_explorer/analysis/configuration"
require_relative "rails_dependency_explorer/analysis/pipeline"
require_relative "rails_dependency_explorer/architectural_analysis"
# All core analyzers now loaded via analyzers module: rails_configuration_analyzer, circular_dependency_analyzer, dependency_depth_analyzer, dependency_statistics_calculator, and rails_component_analyzer
require_relative "rails_dependency_explorer/parsing/dependency_parser"
require_relative "rails_dependency_explorer/parsing/ast_node_utils"
require_relative "rails_dependency_explorer/parsing/namespace_builder"
require_relative "rails_dependency_explorer/parsing/content_filter"
require_relative "rails_dependency_explorer/parsing/ast_builder"
require_relative "rails_dependency_explorer/parsing/class_discovery"
require_relative "rails_dependency_explorer/parsing/ast_processor"
require_relative "rails_dependency_explorer/parsing/ast_visitor"
require_relative "rails_dependency_explorer/parsing/dependency_accumulator"
require_relative "rails_dependency_explorer/parsing/node_handler_registry"
require_relative "rails_dependency_explorer/output/dependency_visualizer"
require_relative "rails_dependency_explorer/cli/command"

module RailsDependencyExplorer
  # Base error class for Rails dependency explorer exceptions.
  # Provides a common ancestor for all custom exceptions raised by the gem,
  # enabling consistent error handling and categorization.
  class Error < StandardError; end
end
