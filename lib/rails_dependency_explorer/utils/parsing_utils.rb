# frozen_string_literal: true

# Require the original parsing utilities for delegation
require_relative "../parsing/dependency_parser_utils"
require_relative "../parsing/namespace_builder"
require_relative "../parsing/content_filter"

module RailsDependencyExplorer
  module Utils
    # Parsing-related utility classes and modules.
    # Organizes code parsing and dependency extraction utility functionality.
    # Part of Phase 1.3 utility organization (Tidy First - Structural changes only).
    module ParsingUtils
      # Re-export parsing utilities under Utils namespace while maintaining backward compatibility
      DependencyParserUtils = RailsDependencyExplorer::Parsing::DependencyParserUtils
      NamespaceBuilder = RailsDependencyExplorer::Parsing::NamespaceBuilder
      ContentFilter = RailsDependencyExplorer::Parsing::ContentFilter
    end
  end
end
