# frozen_string_literal: true

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
        ASTBuilder.build_ast(@ruby_code)
      end

      def find_class_nodes(node)
        ClassDiscovery.find_class_nodes(node)
      end

      def find_class_nodes_with_namespace(node, namespace_stack = [])
        ClassDiscovery.find_class_nodes_with_namespace(node, namespace_stack)
      end

      def extract_class_name(ast)
        ASTNodeUtils.extract_class_name(ast)
      end

      # Process Ruby code and return class nodes with their names
      def process_classes
        ast = build_ast
        return [] unless ast

        class_info_list = find_class_nodes_with_namespace(ast)
        return [] if class_info_list.empty?

        # Filter to only include classes/modules that have actual content and non-empty names
        class_info_list.select { |info|
          ContentFilter.has_meaningful_content?(info[:node]) && !info[:full_name].to_s.strip.empty?
        }.map do |class_info|
          {
            name: class_info[:full_name],
            node: class_info[:node]
          }
        end
      end
    end
  end
end
