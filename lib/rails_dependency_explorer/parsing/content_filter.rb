# frozen_string_literal: true

module RailsDependencyExplorer
  module Parsing
    # Handles detection of meaningful content in AST nodes.
    # Extracted from ASTProcessor to reduce complexity and improve testability.
    # Provides specialized logic for identifying classes/modules with actual implementation.
    class ContentFilter
      # Check if a class or module node has meaningful content
      # @param node [Parser::AST::Node] The AST node representing a class or module
      # @return [Boolean] True if the node contains meaningful definitions or method calls
      def self.has_meaningful_content?(node)
        return false unless ASTNodeUtils.has_children?(node)

        # For classes: children[0] = name, children[1] = superclass, children[2+] = body
        # For modules: children[0] = name, children[1+] = body
        body_start_index = node.type == :class ? 2 : 1
        body_nodes = node.children[body_start_index..-1] || []

        # Check if there are any meaningful definitions or method calls
        body_nodes.any? do |child|
          has_meaningful_definitions?(child)
        end
      end

      # Check if a node represents meaningful definitions or method calls
      # @param node [Parser::AST::Node, nil] The AST node to check
      # @return [Boolean] True if the node represents meaningful code
      def self.has_meaningful_definitions?(node)
        return false unless node&.respond_to?(:type)

        # Method definitions
        return true if node.type == :def || node.type == :defs

        # Method calls (like has_many, validates, etc.)
        return true if node.type == :send

        # Check within begin blocks (common for classes with multiple methods/calls)
        if node.type == :begin && ASTNodeUtils.has_children?(node)
          return node.children.any? { |child| has_meaningful_definitions?(child) }
        end

        false
      end
    end
  end
end
