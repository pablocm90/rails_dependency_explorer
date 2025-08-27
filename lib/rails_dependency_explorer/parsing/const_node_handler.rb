# frozen_string_literal: true

require_relative "base_node_handler"

module RailsDependencyExplorer
  module Parsing
    # Handles const node processing for AST traversal.
    # Extracted from ASTVisitor to reduce complexity and improve separation of concerns.
    # Part of H2 refactoring to implement cleaner visitor pattern.
    # Updated in A3 to use BaseNodeHandler abstraction.
    class ConstNodeHandler < BaseNodeHandler
      # Implementation of BaseNodeHandler template method
      # Processes const nodes to extract constant references and nested constant patterns
      # @param node [Parser::AST::Node] The const node to process
      # @return [String, Hash] Either a simple constant name or nested constant structure
      def self.process_node(node)
        first_child = safe_child(node, 0)
        second_child_str = child_string(node, 1)

        if child_type?(node, 0, :const)
          # Handle nested constants like Config::MAX_HEALTH
          parent_const = child_string(first_child, 1)
          {parent_const => [second_child_str]}
        else
          # Plain constant
          second_child_str
        end
      end

      # Extracts full constant name from nested const nodes
      # @param node [Parser::AST::Node] The const node to process
      # @return [String, nil] Full constant name like "Config::MAX_HEALTH" or nil
      def self.extract_full_constant_name(node)
        return nil unless node.type == :const

        parts = extract_constant_parts(node)
        build_constant_name(parts)
      end
    end
  end
end
