# frozen_string_literal: true

require "parser/current"
require "stringio"

module RailsDependencyExplorer
  module Parsing
    # Handles AST processing operations for Ruby source code.
    # Separates AST building, traversal, and class discovery concerns
    # from dependency extraction coordination, following SRP.
    # Extracted from DependencyParser as part of H4 refactoring.
    class ASTProcessor
      def initialize(ruby_code)
        @ruby_code = ruby_code
      end

      def build_ast
        parser = Parser::CurrentRuby
        # Suppress parser diagnostic messages during parsing
        original_stderr = $stderr
        $stderr = StringIO.new
        parser.parse(@ruby_code)
      rescue Parser::SyntaxError
        nil
      ensure
        $stderr = original_stderr
      end

      def find_class_nodes(node)
        return [] unless node.respond_to?(:type)

        class_nodes = []

        # If this node is a class or module, add it
        class_nodes << node if node.type == :class || node.type == :module

        # Recursively search children for class and module nodes
        if node.respond_to?(:children) && node.children
          node.children.each do |child|
            class_nodes.concat(find_class_nodes(child))
          end
        end

        class_nodes
      end

      def extract_class_name(ast)
        class_name_node = ast.children.first
        return "" unless class_name_node&.children&.[](1)

        class_name_node.children[1].to_s
      end

      # Process Ruby code and return class nodes with their names
      def process_classes
        ast = build_ast
        return [] unless ast

        class_nodes = find_class_nodes(ast)
        return [] if class_nodes.empty?

        class_nodes.map do |class_node|
          class_name = extract_class_name(class_node)
          next unless class_name && !class_name.empty?

          {
            name: class_name,
            node: class_node
          }
        end.compact
      end
    end
  end
end
