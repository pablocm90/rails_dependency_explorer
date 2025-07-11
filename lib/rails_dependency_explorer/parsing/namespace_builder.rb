# frozen_string_literal: true

module RailsDependencyExplorer
  module Parsing
    # Handles namespace path building and management for AST processing.
    # Extracted from ASTProcessor to reduce complexity and improve testability.
    # Provides immutable namespace operations following functional programming principles.
    class NamespaceBuilder
      attr_reader :namespace_stack

      # Initialize with an optional namespace stack
      # @param namespace_stack [Array<String>] The current namespace stack
      def initialize(namespace_stack = [])
        @namespace_stack = namespace_stack.dup.freeze
      end

      # Build a full namespace name by combining the current stack with an immediate name
      # @param immediate_name [String] The immediate class/module name to append
      # @return [String] The full namespaced name (e.g., "App::Models::User")
      def build_full_name(immediate_name)
        (@namespace_stack + [immediate_name]).join("::")
      end

      # Create a new NamespaceBuilder with an additional namespace pushed onto the stack
      # @param namespace_name [String] The namespace to push
      # @return [NamespaceBuilder] A new instance with the updated namespace stack
      def push_namespace(namespace_name)
        NamespaceBuilder.new(@namespace_stack + [namespace_name])
      end

      # Build a complete class info structure for AST processing
      # @param node [Parser::AST::Node] The AST node representing the class/module
      # @param immediate_name [String] The immediate class/module name
      # @return [Hash] Complete class info with node, full_name, namespace_stack, and type
      def build_class_info(node, immediate_name)
        {
          node: node,
          full_name: build_full_name(immediate_name),
          namespace_stack: @namespace_stack.dup,
          type: node.type
        }
      end
    end
  end
end
