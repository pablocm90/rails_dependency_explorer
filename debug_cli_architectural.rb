#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative 'lib/rails_dependency_explorer'

puts "🔍 Debugging CLI Architectural Analysis Integration"
puts "=" * 60

# Create test data similar to what CLI would process
dependency_data = {
  "App::Models::User" => [{"Services::UserService" => ["validate"]}],
  "Services::UserService" => [{"App::Models::User" => ["find"]}]
}

puts "\n1. Testing AnalysisResult directly:"
result = RailsDependencyExplorer::Analysis::AnalysisResult.new(dependency_data)

puts "Cross-namespace cycles detected: #{result.cross_namespace_cycles.length}"
result.cross_namespace_cycles.each do |cycle|
  puts "  - #{cycle[:cycle].join(' -> ')}"
end

puts "\n2. Testing console output:"
console_output = result.to_console
puts "Console output includes 'Cross-Namespace Cycles': #{console_output.include?('Cross-Namespace Cycles')}"

puts "\n3. Testing AnalysisResultFormatter directly:"
formatter = RailsDependencyExplorer::Analysis::AnalysisResultFormatter.new(dependency_data, result)
formatter_console = formatter.to_console
puts "Formatter console output includes 'Cross-Namespace Cycles': #{formatter_console.include?('Cross-Namespace Cycles')}"

puts "\n4. Testing CLI OutputWriter:"
output_writer = RailsDependencyExplorer::CLI::OutputWriter.new
cli_output = output_writer.format_output(result, "console", {})
puts "CLI output includes 'Cross-Namespace Cycles': #{cli_output.include?('Cross-Namespace Cycles')}"

puts "\n5. Full console outputs:"
puts "\n--- AnalysisResult.to_console ---"
puts console_output
puts "\n--- AnalysisResultFormatter.to_console ---"  
puts formatter_console
puts "\n--- CLI OutputWriter console format ---"
puts cli_output
