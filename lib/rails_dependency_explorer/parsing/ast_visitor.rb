# frozen_string_literal: true

require_relative "node_handler_registry"

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

      private

      def register_default_handlers
        @registry.register(:const, method(:visit_const))
        @registry.register(:send, method(:visit_send))
      end

      def visit_const(node)
        node_children = node.children
        if node_children[0]&.type == :const
          # Handle nested constants like Config::MAX_HEALTH
          parent_const = node_children[0].children[1].to_s
          child_const = node_children[1].to_s
          {parent_const => [child_const]}
        else
          # Plain constant
          node_children[1].to_s
        end
      end

      def visit_send(node)
        receiver = node.children[0]

        if direct_constant_call?(receiver)
          extract_direct_constant_call(receiver, node)
        elsif chained_constant_call?(receiver)
          extract_chained_constant_call(receiver)
        else
          visit_children(node)
        end
      end

      private

      def direct_constant_call?(receiver)
        self.class.direct_constant_call?(receiver)
      end

      def chained_constant_call?(receiver)
        self.class.chained_constant_call?(receiver)
      end

      def extract_direct_constant_call(receiver, node)
        self.class.extract_direct_constant_call(receiver, node)
      end

      def extract_chained_constant_call(receiver)
        self.class.extract_chained_constant_call(receiver)
      end

      def self.direct_constant_call?(receiver)
        receiver&.type == :const
      end

      def self.chained_constant_call?(receiver)
        receiver&.type == :send && receiver.children[0]&.type == :const
      end

      def self.extract_direct_constant_call(receiver, node)
        const_name = receiver.children[1].to_s
        method_name = node.children[1].to_s
        {const_name => [method_name]}
      end

      def self.extract_chained_constant_call(receiver)
        # Handle chained calls like GameState.current.update - only track first method
        receiver_children = receiver.children
        const_name = receiver_children[0].children[1].to_s
        method_name = receiver_children[1].to_s
        {const_name => [method_name]}
      end

      def visit_children(node)
        node.children.map { |child| visit(child) }.flatten
      end

      def primitive_type?(node)
        node.is_a?(Symbol) || node.is_a?(String) || node.is_a?(Integer)
      end
    end
  end
end
