# frozen_string_literal: true

# Require the original formatting utilities for delegation
require_relative "../architectural_analysis/architectural_cycle_formatter"

module RailsDependencyExplorer
  module Utils
    # Formatting-related utility classes and modules.
    # Organizes data formatting and presentation utility functionality.
    # Part of Phase 1.3 utility organization (Tidy First - Structural changes only).
    module FormattingUtils
      # Re-export formatting utilities under Utils namespace while maintaining backward compatibility
      ArchitecturalCycleFormatter = RailsDependencyExplorer::ArchitecturalAnalysis::ArchitecturalCycleFormatter
    end
  end
end
