# frozen_string_literal: true

# Require the original state utilities for delegation
require_relative "../analysis/dfs_state"
require_relative "../analysis/depth_calculation_state"

module RailsDependencyExplorer
  module Utils
    # State management utility classes and modules.
    # Organizes state tracking and management utility functionality for algorithms.
    # Part of Phase 1.3 utility organization (Tidy First - Structural changes only).
    module StateUtils
      # Re-export state utilities under Utils namespace while maintaining backward compatibility
      DfsState = RailsDependencyExplorer::Analysis::DfsState
      DepthCalculationState = RailsDependencyExplorer::Analysis::DepthCalculationState
    end
  end
end
