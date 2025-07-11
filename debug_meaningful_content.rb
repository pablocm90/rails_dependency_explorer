#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative 'lib/rails_dependency_explorer'

ruby_code = <<~RUBY
  module UserHelpers
    def format_name
      StringUtils.capitalize(name)
    end
  end

  class User
    def initialize
      UserHelpers.format_name
    end

    def validate
      Validator.check(self)
    end
  end
RUBY

puts "🔍 Debugging Meaningful Content Detection"
puts "=" * 50

processor = RailsDependencyExplorer::Parsing::ASTProcessor.new(ruby_code)

puts "1. Class nodes found:"
class_info_list = processor.process_classes
class_info_list.each do |info|
  puts "  #{info[:name]} (#{info[:type]})"
end

puts "\n2. Testing meaningful content detection:"
class_nodes = processor.send(:find_class_nodes_with_namespace, processor.build_ast)
class_nodes.each do |info|
  has_content = processor.send(:has_meaningful_content?, info[:node])
  puts "  #{info[:full_name]} (#{info[:type]}): #{has_content ? 'HAS' : 'NO'} meaningful content"
  
  # Debug the body nodes
  node = info[:node]
  body_start_index = node.type == :class ? 2 : 1
  body_nodes = node.children[body_start_index..-1] || []
  puts "    Body nodes: #{body_nodes.map { |n| n&.type }}"
  
  # Check each body node
  body_nodes.each_with_index do |child, i|
    if child&.respond_to?(:type)
      puts "      [#{i}] #{child.type}: #{child.type == :def || child.type == :defs ? 'METHOD DEF' : 'OTHER'}"
    end
  end
end
