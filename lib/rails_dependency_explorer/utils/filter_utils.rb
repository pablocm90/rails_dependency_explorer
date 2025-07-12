# frozen_string_literal: true

# Require the original filter utilities for delegation
require_relative "../architectural_analysis/cross_namespace_cycle_filter"

module RailsDependencyExplorer
  module Utils
    # Filtering utility classes and modules.
    # Organizes data filtering and selection utilities.
    # Part of Phase 1.3 utility organization (Tidy First - Structural changes only).
    module FilterUtils
      # Re-export filter utilities under Utils namespace while maintaining backward compatibility
      CrossNamespaceCycleFilter = RailsDependencyExplorer::ArchitecturalAnalysis::CrossNamespaceCycleFilter
    end
  end
end
