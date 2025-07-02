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
        {ast.children[0].children[1].to_s => []}
      end
    end
  end
end
