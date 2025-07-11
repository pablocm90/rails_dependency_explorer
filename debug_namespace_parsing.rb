#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative 'lib/rails_dependency_explorer'
require 'parser/current'

puts "🔍 Debugging Namespace Parsing"
puts "=" * 50

# Test the AST parsing for namespaced classes
ruby_code = <<~RUBY
  module App
    module Models
      class User
        def validate_user
          Services::UserService.new.validate(self)
        end
      end
    end
  end

  module Services
    class UserService
      def validate(user)
        App::Models::User.find(user.id)
      end
    end
  end
RUBY

puts "1. Testing AST parsing directly:"
parser = Parser::CurrentRuby
ast = parser.parse(ruby_code)

def find_class_nodes(node)
  return [] unless node.respond_to?(:type)
  
  class_nodes = []
  class_nodes << node if node.type == :class || node.type == :module
  
  if node.respond_to?(:children) && node.children
    node.children.each do |child|
      class_nodes.concat(find_class_nodes(child))
    end
  end
  
  class_nodes
end

def extract_class_name_debug(ast)
  class_name_node = ast.children.first
  puts "  Class name node: #{class_name_node.inspect}"
  puts "  Class name node children: #{class_name_node&.children.inspect}"
  return "" unless class_name_node&.children&.[](1)
  
  result = class_name_node.children[1].to_s
  puts "  Extracted name: #{result}"
  result
end

class_nodes = find_class_nodes(ast)
puts "Found #{class_nodes.length} class/module nodes:"

class_nodes.each_with_index do |node, i|
  puts "\n--- Node #{i + 1} (#{node.type}) ---"
  name = extract_class_name_debug(node)
  puts "Final name: '#{name}'"
end

puts "\n2. Testing with DependencyParser:"
dependency_parser = RailsDependencyExplorer::Parsing::DependencyParser.new(ruby_code)
result = dependency_parser.parse
puts "Parsed dependencies:"
result.each do |class_name, deps|
  puts "  #{class_name}: #{deps}"
end

puts "\n3. Testing with DependencyExplorer:"
explorer = RailsDependencyExplorer::Analysis::DependencyExplorer.new
analysis_result = explorer.analyze_code(ruby_code)
puts "Analysis result dependencies:"
analysis_result.dependency_data.each do |class_name, deps|
  puts "  #{class_name}: #{deps}"
end
