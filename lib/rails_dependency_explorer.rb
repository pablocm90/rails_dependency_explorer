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
require_relative "rails_dependency_explorer/utils"
require_relative "rails_dependency_explorer/analysis/analyzer_interface"
require_relative "rails_dependency_explorer/analysis/cycle_detection_interface"
require_relative "rails_dependency_explorer/analysis/statistics_interface"
require_relative "rails_dependency_explorer/analysis/dependency_container"
require_relative "rails_dependency_explorer/analysis/dependency_explorer"
require_relative "rails_dependency_explorer/analysis/analysis_result"
require_relative "rails_dependency_explorer/analysis/dependency_collection"
require_relative "rails_dependency_explorer/analysis/circular_dependency_analyzer"
require_relative "rails_dependency_explorer/analysis/dependency_depth_analyzer"
require_relative "rails_dependency_explorer/analysis/dependency_statistics_calculator"
require_relative "rails_dependency_explorer/analysis/rails_component_analyzer"
require_relative "rails_dependency_explorer/analysis/rails_configuration_analyzer"
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
