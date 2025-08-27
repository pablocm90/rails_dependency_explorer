# frozen_string_literal: true

require_relative "format_strategy_registry"

module RailsDependencyExplorer
  module CLI
    # Handles output writing and formatting for the Rails dependency explorer CLI.
    # Coordinates with format adapters to generate output in various formats (console, JSON, HTML, DOT, CSV)
    # and manages writing to files or standard output based on user preferences.
    # Refactored to use strategy pattern instead of case statements (A2: Replace Complex Conditionals).
    class OutputWriter
      def initialize
        @format_registry = FormatStrategyRegistry.new
      end
      def write_output(content, output_file)
        if output_file.nil?
          # Write to stdout
          puts content
        else
          # Write to file
          begin
            File.write(output_file, content)
          rescue => e
            puts "Error writing to file '#{output_file}': #{e.message}"
            raise e
          end
        end
      end

      def format_output(result, format, options = {})
        strategy = @format_registry.get_strategy(format)
        strategy.call(result, options)
      end

      def self.format_statistics(stats)
        "\n\nStatistics:\n" \
          "  Total Classes: #{stats[:total_classes]}\n" \
          "  Total Dependencies: #{stats[:total_dependencies]}\n" \
          "  Most Used Dependency: #{stats[:most_used_dependency]}\n"
      end

      def self.format_circular_dependencies(cycles)
        output = "\n\nCircular Dependencies:\n"
        if cycles.empty?
          output += "  None detected\n"
        else
          cycles.each do |cycle|
            output += "  #{cycle.join(" -> ")}\n"
          end
        end
        output
      end

      def self.format_dependency_depth(depths)
        output = "\n\nDependency Depth:\n"
        depths.each do |class_name, depth|
          output += "  #{class_name}: #{depth}\n"
        end
        output
      end

      private

      def format_statistics(stats)
        self.class.format_statistics(stats)
      end

      def format_circular_dependencies(cycles)
        self.class.format_circular_dependencies(cycles)
      end

      def format_dependency_depth(depths)
        self.class.format_dependency_depth(depths)
      end
    end
  end
end
