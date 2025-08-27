# frozen_string_literal: true

require_relative "node_handler_registry"
require_relative "const_node_handler"
require_relative "send_node_handler"

module RailsDependencyExplorer
  module Parsing
    # Visits Abstract Syntax Tree nodes to extract dependency information.
    # Traverses Ruby AST nodes to identify constant references, method calls,
    # and other dependency patterns, using a registry-based handler system.
    class ASTVisitor
      attr_reader :registry

      def initialize
        @registry = NodeHandlerRegistry.new
        register_default_handlers
      end

      def visit(node)
        return [] unless node
        return [] if primitive_type?(node)

        node_type = node.type
        if @registry.registered?(node_type)
          @registry.handle(node_type, node)
        else
          visit_children(node)
        end
      end

      def visit_children(node)
        node.children.map { |child| visit(child) }.flatten
      end

      private

      def register_default_handlers
        @registry.register(:const, ->(node) { ConstNodeHandler.handle(node) })
        @registry.register(:send, ->(node) { SendNodeHandler.handle(node, self) })
      end





      def primitive_type?(node)
        node.is_a?(Symbol) || node.is_a?(String) || node.is_a?(Integer) || node.is_a?(Float)
      end



    end
  end
end
