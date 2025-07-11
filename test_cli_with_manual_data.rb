#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative 'lib/rails_dependency_explorer'

puts "🧪 Testing CLI with Manual Namespaced Data"
puts "=" * 50

# Create dependency data with proper namespaces (simulating what should be parsed)
dependency_data = {
  "App::Models::User" => [{"Services::UserService" => ["validate"]}],
  "Services::UserService" => [{"App::Models::User" => ["find"]}]
}

puts "1. Creating AnalysisResult with namespaced data:"
result = RailsDependencyExplorer::Analysis::AnalysisResult.new(dependency_data)

puts "Cross-namespace cycles detected: #{result.cross_namespace_cycles.length}"
result.cross_namespace_cycles.each do |cycle|
  puts "  - #{cycle[:cycle].join(' -> ')}"
end

puts "\n2. Testing CLI OutputWriter with this data:"
output_writer = RailsDependencyExplorer::CLI::OutputWriter.new

# Test console format (default)
console_output = output_writer.format_output(result, "graph", {})
puts "--- Console Output ---"
puts console_output

puts "\n3. Testing with stats and circular flags:"
console_with_flags = output_writer.format_output(result, "graph", {
  include_stats: true,
  include_circular: true
})
puts "--- Console Output with Flags ---"
puts console_with_flags

puts "\n4. Testing JSON format:"
json_output = output_writer.format_output(result, "json", {})
puts "--- JSON Output (first 200 chars) ---"
puts json_output[0..200] + "..."
