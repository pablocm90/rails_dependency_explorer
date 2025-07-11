#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative 'lib/rails_dependency_explorer'

puts "🔍 Full CLI Execution Debug"
puts "=" * 50

# Simulate the exact CLI call: analyze --directory test_cli_app --format graph
args = ["analyze", "--directory", "test_cli_app", "--format", "graph"]

puts "1. CLI Arguments: #{args.inspect}"

puts "\n2. Creating CLI Command:"
cli = RailsDependencyExplorer::CLI::Command.new(args)

puts "\n3. Running CLI Command:"
exit_code = cli.run
puts "Exit code: #{exit_code}"
