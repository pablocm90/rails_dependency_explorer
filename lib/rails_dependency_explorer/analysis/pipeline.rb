# frozen_string_literal: true

# Pipeline module - Contains pipeline coordination and result management classes
# Part of structural reorganization to improve codebase organization

require_relative "pipeline/analysis_pipeline"
require_relative "pipeline/analysis_result"
require_relative "pipeline/analysis_result_builder"
require_relative "pipeline/analysis_result_formatter"
require_relative "pipeline/analyzer_registry"
require_relative "pipeline/dependency_explorer"

module RailsDependencyExplorer
  module Analysis
    # Namespace for pipeline coordination and result management classes
    # Contains classes that orchestrate analysis execution and manage results
    module Pipeline
      # This module contains all pipeline and coordination classes
    end
  end
end
