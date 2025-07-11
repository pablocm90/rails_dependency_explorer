#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative 'lib/rails_dependency_explorer'

puts "🔍 Debugging CLI Flow"
puts "=" * 50

# Test the same files that CLI would process
directory_path = "test_cli_app"

puts "1. Testing DependencyExplorer.analyze_directory:"
explorer = RailsDependencyExplorer::Analysis::DependencyExplorer.new
result = explorer.analyze_directory(directory_path)

puts "Raw dependency data: #{result.instance_variable_get(:@dependency_data).inspect}"

puts "\n2. Testing AnalysisResult.to_console:"
console_output = result.to_console
puts console_output

puts "\n3. Testing cross-namespace cycles:"
cycles = result.cross_namespace_cycles
puts "Cross-namespace cycles: #{cycles.inspect}"

puts "\n4. Testing architectural analysis extraction:"
formatter = result.send(:formatter)
architectural_analysis = formatter.send(:extract_architectural_analysis)
puts "Architectural analysis: #{architectural_analysis.inspect}"
