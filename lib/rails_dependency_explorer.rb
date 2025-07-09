# frozen_string_literal: true

require_relative "rails_dependency_explorer/version"
require_relative "rails_dependency_explorer/analysis/dependency_explorer"
require_relative "rails_dependency_explorer/analysis/analysis_result"
require_relative "rails_dependency_explorer/analysis/dependency_collection"
require_relative "rails_dependency_explorer/analysis/circular_dependency_analyzer"
require_relative "rails_dependency_explorer/analysis/dependency_depth_analyzer"
require_relative "rails_dependency_explorer/analysis/dependency_statistics_calculator"
require_relative "rails_dependency_explorer/parsing/dependency_parser"
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
