# frozen_string_literal: true

module RailsDependencyExplorer
  module Parsing
    class NodeHandlerRegistry
    attr_reader :handlers

    def initialize
      @handlers = {}
    end

    def register(node_type, handler)
      @handlers[node_type] = handler
    end

    def handle(node_type, node)
      handler = @handlers[node_type]
      handler&.call(node)
    end

    def registered?(node_type)
      @handlers.key?(node_type)
    end
    end
  end
end
