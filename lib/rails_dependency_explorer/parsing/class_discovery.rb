# frozen_string_literal: true

module RailsDependencyExplorer
  module Parsing
    # Handles discovery of class and module nodes in AST structures.
    # Extracted from ASTProcessor to reduce complexity and improve testability.
    # Provides specialized logic for finding and organizing class/module definitions.
    class ClassDiscovery
      # Find all class and module nodes in an AST
      # @param node [Parser::AST::Node, nil] The AST node to search
      # @return [Array<Parser::AST::Node>] Array of class and module nodes
      def self.find_class_nodes(node)
        return [] unless node.respond_to?(:type)

        class_nodes = []

        # If this node is a class or module, add it
        class_nodes << node if ASTNodeUtils.class_or_module_node?(node)

        # Recursively search children for class and module nodes
        ASTNodeUtils.traverse_children(node) do |child|
          class_nodes.concat(find_class_nodes(child))
        end

        class_nodes
      end

      # Find all class and module nodes with their full namespace paths
      # @param node [Parser::AST::Node, nil] The AST node to search
      # @param namespace_stack [Array<String>] Initial namespace stack
      # @return [Array<Hash>] Array of hashes with :node, :full_name keys
      def self.find_class_nodes_with_namespace(node, namespace_stack = [])
        return [] unless node.respond_to?(:type)

        namespace_builder = NamespaceBuilder.new(namespace_stack)
        find_class_nodes_with_namespace_builder(node, namespace_builder)
      end

      private

      # Internal recursive method for namespace-aware class discovery
      # @param node [Parser::AST::Node] The AST node to search
      # @param namespace_builder [NamespaceBuilder] The namespace builder instance
      # @return [Array<Hash>] Array of class info hashes
      def self.find_class_nodes_with_namespace_builder(node, namespace_builder)
        return [] unless node.respond_to?(:type)

        class_nodes = []

        if ASTNodeUtils.class_or_module_node?(node)
          # Extract the immediate name using utility
          immediate_name = ASTNodeUtils.extract_class_name(node)

          # Build class info using namespace builder
          class_nodes << namespace_builder.build_class_info(node, immediate_name)

          # Continue searching children with updated namespace builder
          new_namespace_builder = namespace_builder.push_namespace(immediate_name)
          if ASTNodeUtils.has_children?(node)
            node.children[1..].each do |child|  # Skip the name node
              class_nodes.concat(find_class_nodes_with_namespace_builder(child, new_namespace_builder))
            end
          end
        else
          # Not a class/module, but continue searching children
          ASTNodeUtils.traverse_children(node) do |child|
            class_nodes.concat(find_class_nodes_with_namespace_builder(child, namespace_builder))
          end
        end

        class_nodes
      end
    end
  end
end
