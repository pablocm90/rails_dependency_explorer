#!/usr/bin/env ruby
# frozen_string_literal: true

require 'parser/current'

puts "🔍 Debugging Constant vs Method Call AST"
puts "=" * 50

test_cases = [
  "Config::MAX_HEALTH",           # Pure constant reference
  "App::Models::User.find(1)",    # Method call on constant
  "Services::UserService.new"     # Method call on constant
]

test_cases.each do |code|
  puts "\n--- Testing: #{code} ---"
  
  parser = Parser::CurrentRuby
  ast = parser.parse(code)
  
  puts "AST: #{ast.inspect}"
  puts "Root type: #{ast.type}"
  
  if ast.type == :const
    puts "This is a pure constant reference"
  elsif ast.type == :send
    puts "This is a method call"
    puts "Receiver: #{ast.children[0].inspect}"
    puts "Method: #{ast.children[1]}"
  end
end
