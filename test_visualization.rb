#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "lib/rails_dependency_explorer/dependency_visualizer"

# Test with simple dependency data

# Test with more complex dependency data (from our existing tests)
complex_data = {
  "Player" => [
    {"Enemy" => ["take_damage", "health"]},
    {"GameState" => ["current"]},
    {"Config" => ["MAX_HEALTH"]},
    {"Logger" => ["info"]}
  ],
  "Enemy" => [
    {"Player" => ["health"]},
    {"Logger" => ["info"]}
  ]
}

dependency_data = complex_data

visualizer = RailsDependencyExplorer::DependencyVisualizer.new

# Generate graph structure
graph = visualizer.to_graph(dependency_data)
puts "Graph structure:"
puts graph.inspect
puts

# Generate DOT format
dot_output = visualizer.to_dot(dependency_data)
puts "DOT format:"
puts dot_output
puts

# Save DOT to file for visualization
File.write("dependency_graph.dot", dot_output)
puts "DOT file saved as 'dependency_graph.dot'"
puts "To visualize, run: dot -Tpng dependency_graph.dot -o dependency_graph.png"
puts "Or view online at: https://dreampuf.github.io/GraphvizOnline/"
