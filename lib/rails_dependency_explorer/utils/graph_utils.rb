# frozen_string_literal: true

# Require the original GraphBuilder for delegation
require_relative "../analysis/graph_builder"

module RailsDependencyExplorer
  module Utils
    # Graph-related utility classes and modules.
    # Organizes graph construction and manipulation utilities.
    # Part of Phase 1.3 utility organization (Tidy First - Structural changes only).
    module GraphUtils
      # Re-export GraphBuilder under Utils namespace while maintaining backward compatibility
      GraphBuilder = RailsDependencyExplorer::Analysis::GraphBuilder
    end
  end
end
