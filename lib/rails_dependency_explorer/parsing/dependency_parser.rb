# frozen_string_literal: true

require "parser/current"
require_relative "dependency_accumulator"
require_relative "ast_visitor"

module RailsDependencyExplorer
  module Parsing
    class DependencyParser
      def initialize(ruby_code)
        @ruby_code = ruby_code
      end

      def parse
        ast = build_ast
        return {} unless ast

        # Find all class definitions in the AST
        class_nodes = find_class_nodes(ast)
        return {} if class_nodes.empty?

        # Process each class and merge results
        result = {}
        class_nodes.each do |class_node|
          class_name = extract_class_name(class_node)
          dependencies = extract_dependencies(class_node)
          result[class_name] = dependencies if class_name && !class_name.empty?
        end

        result
      end

      private

      def find_class_nodes(node)
        return [] unless node.respond_to?(:type)

        class_nodes = []

        # If this node is a class, add it
        class_nodes << node if node.type == :class

        # Recursively search children for class nodes
        if node.respond_to?(:children) && node.children
          node.children.each do |child|
            class_nodes.concat(find_class_nodes(child))
          end
        end

        class_nodes
      end

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
end
