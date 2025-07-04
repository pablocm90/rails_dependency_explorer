# frozen_string_literal: true

require_relative "node_handler_registry"

module RailsDependencyExplorer
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
        { parent_const => [child_const] }
      else
        # Plain constant
        node.children[1].to_s
      end
    end

    def visit_send(node)
      receiver = node.children[0]

      if receiver&.type == :const
        const_name = receiver.children[1].to_s
        method_name = node.children[1].to_s
        { const_name => [method_name] }
      elsif receiver&.type == :send && receiver.children[0]&.type == :const
        # Handle chained calls like GameState.current.update - only track first method
        const_name = receiver.children[0].children[1].to_s
        method_name = receiver.children[1].to_s
        { const_name => [method_name] }
      else
        visit_children(node)
      end
    end

    def visit_children(node)
      node.children.map { |child| visit(child) }.flatten
    end

    def primitive_type?(node)
      node.is_a?(Symbol) || node.is_a?(String) || node.is_a?(Integer)
    end
  end
end
