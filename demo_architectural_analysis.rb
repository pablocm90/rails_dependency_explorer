#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative 'lib/rails_dependency_explorer'

puts "🏗️  Rails Dependency Explorer - Architectural Analysis Demo"
puts "=" * 60

# Sample data with cross-namespace cycles
dependency_data = {
  "App::Models::User" => [{"Services::UserService" => ["validate"]}],
  "Services::UserService" => [{"App::Models::User" => ["find"]}],
  "Controllers::UsersController" => [{"App::Models::User" => ["create"]}],
  "App::Models::Order" => [{"Services::PaymentService" => ["process"]}],
  "Services::PaymentService" => [{"App::Models::Order" => ["update_status"]}]
}

result = RailsDependencyExplorer::Analysis::AnalysisResult.new(dependency_data)

puts "\n📊 CONSOLE OUTPUT:"
puts "-" * 40
puts result.to_console

puts "\n📋 JSON OUTPUT (Cross-Namespace Cycles Section):"
puts "-" * 40
json_output = result.to_json
parsed = JSON.parse(json_output)
if parsed["architectural_analysis"] && parsed["architectural_analysis"]["cross_namespace_cycles"]
  puts JSON.pretty_generate(parsed["architectural_analysis"]["cross_namespace_cycles"])
else
  puts "No architectural analysis found in JSON output"
end

puts "\n📈 CSV OUTPUT (First few lines):"
puts "-" * 40
csv_lines = result.to_csv.split("\n")
csv_lines[0..5].each { |line| puts line }

puts "\n🎯 DOT OUTPUT (Excerpt showing architectural styling):"
puts "-" * 40
dot_output = result.to_dot
dot_lines = dot_output.split("\n")
architectural_lines = dot_lines.select { |line| line.include?('color="red"') || line.include?('cluster_legend') }
architectural_lines.each { |line| puts line.strip }

puts "\n✅ Demo completed! Cross-namespace cycles detected and integrated into all output formats."
