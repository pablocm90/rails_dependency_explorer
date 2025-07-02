# frozen_string_literal: true

require "parser/current"

module RailsDependencyExplorer
  class DependencyParser
    def initialize(ruby_code)
      @ruby_code = ruby_code
    end

    def parse
      parser = Parser::CurrentRuby
      ast = parser.parse(@ruby_code)
      if ast.type == :class
        first_chilfd = ast.children.first
        label = first_chilfd.children[1].to_s
        dependencies = ast.children[1..-1].map do |child|
          find_constants(child)
        end.flatten
        { label => dependencies }
      end
    end

    def find_constants(node)
      return [] unless node
      return [] if node.is_a?(Symbol) || node.is_a?(String) || node.is_a?(Integer)

      if node.type == :const
        node.children[1].to_s
      else
        node.children.map { |child| find_constants(child) }.flatten
      end
    end
  end
end
