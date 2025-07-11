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

      def find_class_nodes_with_namespace(node, namespace_stack = [])
        return [] unless node.respond_to?(:type)

        class_nodes = []

        if node.type == :class || node.type == :module
          # Extract the immediate name
          class_name_node = node.children.first
          immediate_name = class_name_node&.children&.[](1)&.to_s || ""

          # Build full namespace path
          full_name = (namespace_stack + [immediate_name]).join("::")

          # Include both classes and modules in the result
          class_nodes << {
            node: node,
            full_name: full_name,
            namespace_stack: namespace_stack.dup,
            type: node.type
          }

          # Continue searching children with updated namespace stack
          new_namespace_stack = namespace_stack + [immediate_name]
          if node.respond_to?(:children) && node.children
            node.children[1..].each do |child|  # Skip the name node
              class_nodes.concat(find_class_nodes_with_namespace(child, new_namespace_stack))
            end
          end
        else
          # Not a class/module, but continue searching children
          if node.respond_to?(:children) && node.children
            node.children.each do |child|
              class_nodes.concat(find_class_nodes_with_namespace(child, namespace_stack))
            end
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

        class_info_list = find_class_nodes_with_namespace(ast)
        return [] if class_info_list.empty?

        # Filter to only include classes/modules that have actual content and non-empty names
        class_info_list.select { |info|
          has_meaningful_content?(info[:node]) && !info[:full_name].to_s.strip.empty?
        }.map do |class_info|
          {
            name: class_info[:full_name],
            node: class_info[:node]
          }
        end
      end

      private

      def has_meaningful_content?(node)
        return false unless node.respond_to?(:children) && node.children

        # For classes: children[0] = name, children[1] = superclass, children[2+] = body
        # For modules: children[0] = name, children[1+] = body
        body_start_index = node.type == :class ? 2 : 1
        body_nodes = node.children[body_start_index..-1] || []

        # Check if there are any meaningful definitions or method calls
        body_nodes.any? do |child|
          has_meaningful_definitions?(child)
        end
      end

      def has_meaningful_definitions?(node)
        return false unless node&.respond_to?(:type)

        # Method definitions
        return true if node.type == :def || node.type == :defs

        # Method calls (like has_many, validates, etc.)
        return true if node.type == :send

        # Check within begin blocks (common for classes with multiple methods/calls)
        if node.type == :begin && node.respond_to?(:children) && node.children
          return node.children.any? { |child| has_meaningful_definitions?(child) }
        end

        false
      end


    end
  end
end
