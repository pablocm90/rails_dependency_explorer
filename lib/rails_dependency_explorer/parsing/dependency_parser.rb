# frozen_string_literal: true

require_relative "ast_processor"
require_relative "dependency_parser_utils"
require_relative "dependency_accumulator"
require_relative "ast_visitor"

module RailsDependencyExplorer
  module Parsing
    # Main parser for extracting dependencies from Ruby source code.
    # Coordinates dependency extraction workflow by delegating AST processing
    # to specialized classes and focusing on dependency coordination logic.
    class DependencyParser
      def initialize(ruby_code)
        @ruby_code = ruby_code
      end

      def parse
        class_info_list = ast_processor.process_classes
        return {} if class_info_list.empty?

        # Process each class and merge results
        result = {}
        class_info_list.each do |class_info|
          class_name = class_info[:name]
          class_node = class_info[:node]
          dependencies = extract_dependencies(class_node)
          result[class_name] = dependencies if class_name && !class_name.empty?
        end

        result
      end

      # Delegate to utility class for backward compatibility
      def self.extract_class_name(ast)
        DependencyParserUtils.extract_class_name(ast)
      end

      def self.accumulate_visited_dependencies(dependencies, accumulator)
        DependencyParserUtils.accumulate_visited_dependencies(dependencies, accumulator)
      end

      private

      def ast_processor
        @ast_processor ||= ASTProcessor.new(@ruby_code)
      end

      def accumulate_visited_dependencies(dependencies, accumulator)
        self.class.accumulate_visited_dependencies(dependencies, accumulator)
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
    end
  end
end
