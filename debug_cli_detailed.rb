#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative 'lib/rails_dependency_explorer'

puts "🔍 Detailed CLI Debug"
puts "=" * 50

directory_path = "test_cli_app"

puts "1. Testing DependencyParser directly on files:"
ruby_files = Dir.glob(File.join(directory_path, "**", "*.rb"))
ruby_files.each do |file_path|
  puts "\nFile: #{file_path}"
  ruby_code = File.read(file_path)
  puts "Code: #{ruby_code.inspect}"
  
  parser = RailsDependencyExplorer::Parsing::DependencyParser.new(ruby_code)
  result = parser.parse
  puts "Parsed result: #{result.inspect}"
end

puts "\n2. Testing DependencyExplorer.analyze_directory:"
explorer = RailsDependencyExplorer::Analysis::DependencyExplorer.new
result = explorer.analyze_directory(directory_path)
puts "Explorer result: #{result.instance_variable_get(:@dependency_data).inspect}"

puts "\n3. Testing CLI AnalysisExecutor:"
output_writer = RailsDependencyExplorer::CLI::OutputWriter.new
executor = RailsDependencyExplorer::CLI::AnalysisExecutor.new(output_writer)
cli_result = executor.analyze_directory_files(directory_path)
puts "CLI result: #{cli_result.instance_variable_get(:@dependency_data).inspect}"

puts "\n4. Are they the same?"
direct_data = result.instance_variable_get(:@dependency_data)
cli_data = cli_result.instance_variable_get(:@dependency_data)
puts "Direct == CLI: #{direct_data == cli_data}"
puts "Direct: #{direct_data.inspect}"
puts "CLI: #{cli_data.inspect}"
