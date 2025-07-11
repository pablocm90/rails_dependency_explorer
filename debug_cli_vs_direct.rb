#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative 'lib/rails_dependency_explorer'

puts "🔍 Comparing CLI vs Direct Analysis"
puts "=" * 50

directory_path = "test_cli_app"

puts "1. Direct DependencyExplorer call:"
explorer1 = RailsDependencyExplorer::Analysis::DependencyExplorer.new
result1 = explorer1.analyze_directory(directory_path)
puts "Direct result: #{result1.instance_variable_get(:@dependency_data).inspect}"

puts "\n2. CLI AnalysisExecutor call:"
output_writer = RailsDependencyExplorer::CLI::OutputWriter.new
executor = RailsDependencyExplorer::CLI::AnalysisExecutor.new(output_writer)
result2 = executor.analyze_directory_files(directory_path)
puts "CLI result: #{result2.instance_variable_get(:@dependency_data).inspect}"

puts "\n3. Are they the same? #{result1.instance_variable_get(:@dependency_data) == result2.instance_variable_get(:@dependency_data)}"

puts "\n4. Direct console output:"
puts result1.to_console

puts "\n5. CLI console output:"
puts result2.to_console
