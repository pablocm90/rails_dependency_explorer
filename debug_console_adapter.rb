#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative 'lib/rails_dependency_explorer'

puts "🔍 Debugging Console Adapter"
puts "=" * 50

directory_path = "test_cli_app"

puts "1. Testing full pipeline:"
explorer = RailsDependencyExplorer::Analysis::DependencyExplorer.new
result = explorer.analyze_directory(directory_path)

puts "Raw dependency data: #{result.instance_variable_get(:@dependency_data).inspect}"

puts "\n2. Testing to_graph conversion:"
graph = result.to_graph
puts "Graph nodes: #{graph[:nodes].inspect}"
puts "Graph edges: #{graph[:edges].inspect}"

puts "\n3. Testing console format:"
console_output = result.to_console
puts "Console output:"
puts console_output

puts "\n4. Testing console adapter directly:"
direct_console = RailsDependencyExplorer::Output::ConsoleFormatAdapter.format(graph)
puts "Direct console output:"
puts direct_console

puts "\n5. Are they the same?"
puts "Same output: #{console_output == direct_console}"
