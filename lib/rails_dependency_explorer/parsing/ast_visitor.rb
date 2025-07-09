# frozen_string_literal: true

require_relative "node_handler_registry"

module RailsDependencyExplorer
  module Parsing
    class ASTVisitor
      attr_reader :registry

      def initialize
        @registry = NodeHandlerRegistry.new
        register_default_handlers
      end

      def visit(node)
        return [] unless node
        return [] if primitive_type?(node)

        if @registry.registered?(node.type)
          @registry.handle(node.type, node)
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
        if node.children[0]&.type == :const
          # Handle nested constants like Config::MAX_HEALTH
          parent_const = node.children[0].children[1].to_s
          child_const = node.children[1].to_s
          {parent_const => [child_const]}
        else
          # Plain constant
          node.children[1].to_s
        end
      end

      def visit_send(node)
        receiver = node.children[0]

        if direct_constant_call?(receiver)
          extract_direct_constant_call(receiver, node)
        elsif chained_constant_call?(receiver)
          extract_chained_constant_call(receiver, node)
        else
          visit_children(node)
        end
      end

      private

      def direct_constant_call?(receiver)
        receiver&.type == :const
      end

      def chained_constant_call?(receiver)
        receiver&.type == :send && receiver.children[0]&.type == :const
      end

      def extract_direct_constant_call(receiver, node)
        const_name = receiver.children[1].to_s
        method_name = node.children[1].to_s
        {const_name => [method_name]}
      end

      def extract_chained_constant_call(receiver, node)
        # Handle chained calls like GameState.current.update - only track first method
        const_name = receiver.children[0].children[1].to_s
        method_name = receiver.children[1].to_s
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
