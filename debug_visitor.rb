#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative 'lib/rails_dependency_explorer'

puts "🔍 Debugging ASTVisitor Constant Extraction"
puts "=" * 60

# Test the specific case that's failing
ruby_code = <<~RUBY
  class User
    def validate
      App::Models::Profile.create
    end
  end
RUBY

puts "1. Testing DependencyParser with debug:"
parser = RailsDependencyExplorer::Parsing::DependencyParser.new(ruby_code)
result = parser.parse
puts "Result: #{result.inspect}"

puts "\n2. Testing ASTVisitor directly:"
require 'parser/current'

ast_parser = Parser::CurrentRuby
ast = parser_ast = ast_parser.parse(ruby_code)

# Find the class node
def find_class_nodes(node)
  return [] unless node.respond_to?(:type)
  class_nodes = []
  class_nodes << node if node.type == :class
  if node.respond_to?(:children) && node.children
    node.children.each { |child| class_nodes.concat(find_class_nodes(child)) }
  end
  class_nodes
end

class_nodes = find_class_nodes(ast)
puts "Found #{class_nodes.length} class nodes"

class_nodes.each_with_index do |class_node, i|
  puts "\n--- Class #{i + 1} ---"
  
  # Extract dependencies using ASTVisitor
  visitor = RailsDependencyExplorer::Parsing::ASTVisitor.new
  accumulator = RailsDependencyExplorer::Parsing::DependencyAccumulator.new
  
  class_node.children[1..].each do |child|
    next unless child
    puts "Processing child: #{child.type} - #{child.inspect}"
    dependencies = visitor.visit(child)
    puts "Visitor returned: #{dependencies.inspect}"
    
    # Accumulate dependencies
    if dependencies.is_a?(Array)
      dependencies.flatten.each do |dep|
        if dep.is_a?(Hash)
          accumulator.record_hash_dependency(dep)
        elsif dep.is_a?(String)
          accumulator.record_method_call(dep, [])
        end
      end
    elsif dependencies.is_a?(Hash)
      accumulator.record_hash_dependency(dependencies)
    elsif dependencies.is_a?(String)
      accumulator.record_method_call(dependencies, [])
    end
  end
  
  puts "Final accumulated dependencies: #{accumulator.collection.to_grouped_array.inspect}"
end

puts "\n3. Testing constant extraction directly:"
# Find the const node for App::Models::Profile
def find_const_nodes(node)
  return [] unless node.respond_to?(:type)
  const_nodes = []
  const_nodes << node if node.type == :const
  if node.respond_to?(:children) && node.children
    node.children.each { |child| const_nodes.concat(find_const_nodes(child)) }
  end
  const_nodes
end

const_nodes = find_const_nodes(ast)
puts "Found #{const_nodes.length} const nodes:"

visitor = RailsDependencyExplorer::Parsing::ASTVisitor.new
const_nodes.each_with_index do |const_node, i|
  puts "  #{i + 1}. #{const_node.inspect}"
  extracted = visitor.send(:extract_full_constant_name, const_node)
  puts "     Extracted: #{extracted}"
end
