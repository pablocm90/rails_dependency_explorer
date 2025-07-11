#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative 'lib/rails_dependency_explorer'
require 'parser/current'

puts "🔍 Debugging Namespace Parsing - Building Full Paths"
puts "=" * 60

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

puts "1. Testing AST parsing with namespace context:"
parser = Parser::CurrentRuby
ast = parser.parse(ruby_code)

def find_class_nodes_with_context(node, namespace_stack = [])
  return [] unless node.respond_to?(:type)
  
  results = []
  
  if node.type == :class || node.type == :module
    # Extract the immediate name
    class_name_node = node.children.first
    immediate_name = class_name_node&.children&.[](1)&.to_s || ""
    
    # Build full namespace path
    full_name = (namespace_stack + [immediate_name]).join("::")
    
    results << {
      type: node.type,
      immediate_name: immediate_name,
      full_name: full_name,
      namespace_stack: namespace_stack.dup,
      node: node
    }
    
    # Continue searching children with updated namespace stack
    new_namespace_stack = namespace_stack + [immediate_name]
    if node.respond_to?(:children) && node.children
      node.children[1..].each do |child|  # Skip the name node
        results.concat(find_class_nodes_with_context(child, new_namespace_stack))
      end
    end
  else
    # Not a class/module, but continue searching children
    if node.respond_to?(:children) && node.children
      node.children.each do |child|
        results.concat(find_class_nodes_with_context(child, namespace_stack))
      end
    end
  end
  
  results
end

class_info = find_class_nodes_with_context(ast)
puts "Found #{class_info.length} class/module nodes with full paths:"

class_info.each_with_index do |info, i|
  puts "  #{i + 1}. #{info[:type]}: #{info[:full_name]} (immediate: #{info[:immediate_name]})"
end

# Filter only classes (not modules)
classes_only = class_info.select { |info| info[:type] == :class }
puts "\nClasses only:"
classes_only.each do |info|
  puts "  - #{info[:full_name]}"
end

puts "\n2. What we need to fix:"
puts "The current parser extracts: #{class_info.map { |i| i[:immediate_name] }}"
puts "But we need: #{classes_only.map { |i| i[:full_name] }}"
