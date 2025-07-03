# frozen_string_literal: true

require "parser/current"
require_relative "dependency_collection"
require_relative "dependency_accumulator"

module RailsDependencyExplorer
  class DependencyParser
    def initialize(ruby_code)
      @ruby_code = ruby_code
    end

    def parse
      ast = build_ast

      return {} unless ast&.type == :class

      class_name = extract_class_name(ast)
      dependencies = extract_dependencies(ast)
      { class_name => dependencies }
    end

    private

    def build_ast
      parser = Parser::CurrentRuby
      parser.parse(@ruby_code)
    end

    def extract_class_name(ast)
      first_child = ast.children.first
      first_child.children[1].to_s
    end

    def extract_dependencies(ast)
      accumulator = DependencyAccumulator.new

      ast.children[1..-1].each do |child|
        dependencies = find_constants(child)
        dependencies.flatten.each do |dep|
          if dep.is_a?(Hash)
            accumulator.collection.merge_hash_dependency(dep)
          elsif dep.is_a?(String)
            # Handle plain string constants (shouldn't happen with current logic)
            accumulator.record_method_call(dep, [])
          end
        end
      end

      accumulator.collection.to_grouped_array
    end

    def find_constants(ast_node)
      return [] unless ast_node
      return [] if primitive_type?(ast_node)

      case ast_node.type
      when :const
        handle_constant(ast_node)
      when :send
        handle_method_call(ast_node)
      else
        ast_node.children.map { |child_node| find_constants(child_node) }.flatten
      end
    end



    def handle_constant(const_node)
      if const_node.children[0]&.type == :const
        # Handle nested constants like Config::MAX_HEALTH
        parent_const = const_node.children[0].children[1].to_s
        child_const = const_node.children[1].to_s
        { parent_const => [child_const] }
      else
        # Plain constant - shouldn't happen in current context
        const_node.children[1].to_s
      end
    end

    def handle_method_call(send_node)
      receiver = send_node.children[0]

      if receiver&.type == :const
        const_name = receiver.children[1].to_s
        method_name = send_node.children[1].to_s
        { const_name => [method_name] }
      elsif receiver&.type == :send && receiver.children[0]&.type == :const
        # Handle chained calls like GameState.current.update - only track first method
        const_name = receiver.children[0].children[1].to_s
        method_name = receiver.children[1].to_s
        { const_name => [method_name] }
      else
        []
      end
    end

    def primitive_type?(ast_node)
      ast_node.is_a?(Symbol) || ast_node.is_a?(String) || ast_node.is_a?(Integer)
    end
  end
end
