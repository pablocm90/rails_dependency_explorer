# frozen_string_literal: true

require "parser/current"
require "stringio"

module RailsDependencyExplorer
  module Parsing
    # Handles AST construction from Ruby source code.
    # Extracted from ASTProcessor to reduce complexity and improve testability.
    # Provides specialized logic for parsing Ruby code with error handling.
    class ASTBuilder
      # Build an AST from Ruby source code
      # @param ruby_code [String] The Ruby source code to parse
      # @return [Parser::AST::Node, nil] The parsed AST or nil if parsing fails
      def self.build_ast(ruby_code)
        parser = Parser::CurrentRuby
        # Suppress parser diagnostic messages during parsing
        original_stderr = $stderr
        $stderr = StringIO.new
        parser.parse(ruby_code)
      rescue Parser::SyntaxError
        nil
      ensure
        $stderr = original_stderr
      end
    end
  end
end
