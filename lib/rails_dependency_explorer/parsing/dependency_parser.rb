# frozen_string_literal: true

require "parser/current"
require_relative "dependency_accumulator"
require_relative "ast_visitor"

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
      {class_name => dependencies}
    end

    private

    def build_ast
      parser = Parser::CurrentRuby
      parser.parse(@ruby_code)
    rescue Parser::SyntaxError
      nil
    end

    def extract_class_name(ast)
      class_name_node = ast.children.first
      return "" unless class_name_node&.children&.[](1)

      class_name_node.children[1].to_s
    end

    def extract_dependencies(ast)
      accumulator = DependencyAccumulator.new
      visitor = ASTVisitor.new

      ast.children[1..].each do |child|
        dependencies = visitor.visit(child)
        accumulate_visited_dependencies(dependencies, accumulator)
      end

      accumulator.collection.to_grouped_array
    end

    def accumulate_visited_dependencies(dependencies, accumulator)
      dependencies = [dependencies] unless dependencies.is_a?(Array)
      dependencies.flatten.each do |dep|
        if dep.is_a?(Hash)
          accumulator.record_hash_dependency(dep)
        elsif dep.is_a?(String)
          # Handle plain string constants (shouldn't happen with current logic)
          accumulator.record_method_call(dep, [])
        end
      end
    end
  end
end
