# frozen_string_literal: true

# Require the original AST utilities for delegation
require_relative "../parsing/ast_builder"
require_relative "../parsing/ast_node_utils"

module RailsDependencyExplorer
  module Utils
    # AST-related utility classes and modules.
    # Organizes Abstract Syntax Tree manipulation and construction utility functionality.
    # Part of Phase 1.3 utility organization (Tidy First - Structural changes only).
    module ASTUtils
      # Re-export AST utilities under Utils namespace while maintaining backward compatibility
      ASTBuilder = RailsDependencyExplorer::Parsing::ASTBuilder
      ASTNodeUtils = RailsDependencyExplorer::Parsing::ASTNodeUtils
    end
  end
end
