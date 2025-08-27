# frozen_string_literal: true

# Interfaces module - Contains all analyzer interface contracts
# Part of structural reorganization to improve codebase organization

require_relative "interfaces/analyzer_interface"
require_relative "interfaces/component_analyzer_interface"
require_relative "interfaces/graph_analyzer_interface"
require_relative "interfaces/statistics_analyzer_interface"
require_relative "interfaces/analyzer_plugin_interface"

module RailsDependencyExplorer
  module Analysis
    # Namespace for all analyzer interface modules
    # Contains interface contracts that define analyzer capabilities
    module Interfaces
      # This module contains all analyzer interfaces
    end
  end
end
