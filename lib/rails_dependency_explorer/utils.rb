# frozen_string_literal: true

# Utility organization module that provides logical grouping of utility classes.
# Organizes scattered utility classes into functional modules for better discoverability
# and maintainability while maintaining 100% backward compatibility through aliases.
#
# Utility modules:
# - GraphUtils: Graph construction and manipulation utilities
# - ASTUtils: Abstract Syntax Tree processing utilities
# - ParsingUtils: Code parsing and dependency extraction utilities
# - FormattingUtils: Data formatting and presentation utilities
# - StateUtils: State management utilities for algorithms
# - FilterUtils: Data filtering and selection utilities

# Require all utility modules
require_relative "utils/graph_utils"
require_relative "utils/ast_utils"
require_relative "utils/parsing_utils"
require_relative "utils/formatting_utils"
require_relative "utils/state_utils"
require_relative "utils/filter_utils"

module RailsDependencyExplorer
  # Main utility organization module that provides logical grouping of utility classes.
  # Organizes scattered utility classes into functional modules for better discoverability
  # and maintainability while maintaining 100% backward compatibility through aliases.
  # Part of Phase 1.3 utility organization (Tidy First - Structural changes only).
  module Utils
    # This module serves as a namespace for organizing utility classes
    # into logical groups for better maintainability and discoverability.
  end
end
