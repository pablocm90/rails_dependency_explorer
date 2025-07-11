#!/usr/bin/env ruby
# frozen_string_literal: true

require 'parser/current'

puts "🔍 Debugging Constant AST Structure"
puts "=" * 50

# Test different constant patterns
test_cases = [
  "User",
  "Services::UserService", 
  "App::Models::User",
  "App::Services::External::ApiClient"
]

test_cases.each do |const_name|
  puts "\n--- Testing: #{const_name} ---"
  
  ruby_code = "#{const_name}.find(1)"
  
  parser = Parser::CurrentRuby
  ast = parser.parse(ruby_code)
  
  puts "Full AST: #{ast.inspect}"
  
  # Find the const node
  def find_const_nodes(node)
    return [] unless node.respond_to?(:type)
    
    const_nodes = []
    const_nodes << node if node.type == :const
    
    if node.respond_to?(:children) && node.children
      node.children.each do |child|
        const_nodes.concat(find_const_nodes(child))
      end
    end
    
    const_nodes
  end
  
  const_nodes = find_const_nodes(ast)
  puts "Const nodes found: #{const_nodes.length}"
  
  const_nodes.each_with_index do |node, i|
    puts "  #{i + 1}. #{node.inspect}"
    puts "     Children: #{node.children.inspect}"
  end
end

puts "\n" + "=" * 50
puts "🧪 Testing Full Namespace Extraction"

def extract_full_constant_name(node)
  return nil unless node.type == :const
  
  parts = []
  current = node
  
  while current && current.type == :const
    parts.unshift(current.children[1].to_s)
    current = current.children[0]
  end
  
  parts.join("::")
end

test_cases.each do |const_name|
  ruby_code = "#{const_name}.find(1)"
  parser = Parser::CurrentRuby
  ast = parser.parse(ruby_code)
  
  const_nodes = []
  def find_const_nodes(node, results)
    return unless node.respond_to?(:type)
    results << node if node.type == :const
    if node.respond_to?(:children) && node.children
      node.children.each { |child| find_const_nodes(child, results) }
    end
  end
  
  find_const_nodes(ast, const_nodes)
  
  puts "\n#{const_name}:"
  const_nodes.each do |node|
    extracted = extract_full_constant_name(node)
    puts "  Extracted: #{extracted}"
  end
end
