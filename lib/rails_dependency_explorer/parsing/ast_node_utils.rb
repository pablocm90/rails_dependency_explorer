# frozen_string_literal: true

module RailsDependencyExplorer
  module Parsing
    # Utility class for low-level AST node operations.
    # Extracted from ASTProcessor to reduce complexity and improve reusability.
    # Provides common patterns for AST node inspection and traversal.
    class ASTNodeUtils
      # Extract the class name from a class or module AST node
      # @param node [Parser::AST::Node] The AST node representing a class or module
      # @return [String] The class name, or empty string if extraction fails
      def self.extract_class_name(node)
        return "" unless node&.respond_to?(:children)
        
        class_name_node = node.children.first
        return "" unless class_name_node&.children&.[](1)

        class_name_node.children[1].to_s
      end

      # Check if a node has children
      # @param node [Parser::AST::Node, nil] The AST node to check
      # @return [Boolean] True if the node has children, false otherwise
      def self.has_children?(node)
        node&.respond_to?(:children) && node.children && !node.children.empty?
      end

      # Traverse all children of a node, yielding each child to the block
      # @param node [Parser::AST::Node, nil] The AST node to traverse
      # @yield [Parser::AST::Node] Each child node
      def self.traverse_children(node)
        return unless has_children?(node)
        
        node.children.each do |child|
          yield child if block_given?
        end
      end

      # Check if a node represents a class or module definition
      # @param node [Parser::AST::Node, nil] The AST node to check
      # @return [Boolean] True if the node is a class or module, false otherwise
      def self.class_or_module_node?(node)
        return false unless node&.respond_to?(:type)
        
        node.type == :class || node.type == :module
      end
    end
  end
end
