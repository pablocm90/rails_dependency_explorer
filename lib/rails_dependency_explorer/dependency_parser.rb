# frozen_string_literal: true

require "parser/current"

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
      ast.children[1..-1].map do |child|
        find_constants(child)
      end.flatten
    end

    def find_constants(ast_node)
      return [] unless ast_node
      return [] if primitive_type?(ast_node)

      if ast_node.type == :const
        ast_node.children[1].to_s
      else
        ast_node.children.map { |child_node| find_constants(child_node) }.flatten
      end
    end

    def primitive_type?(ast_node)
      ast_node.is_a?(Symbol) || ast_node.is_a?(String) || ast_node.is_a?(Integer)
    end
  end
end
