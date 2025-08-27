# frozen_string_literal: true

module RailsDependencyExplorer
  module CLI
    # Registry for output format strategies used by OutputWriter.
    # Replaces case statement logic with polymorphic dispatch following Open/Closed Principle.
    # Part of A2 refactoring to replace complex conditionals with polymorphism.
    class FormatStrategyRegistry
      def initialize
        @strategies = {}
        register_default_strategies
      end

      # Register a format strategy
      # @param format [String] The format identifier (e.g., "json", "html")
      # @param strategy [Proc, Object] Strategy object or proc that responds to call(result, options)
      def register(format, strategy)
        @strategies[format.to_s] = strategy
      end

      # Get strategy for a format, with fallback to default
      # @param format [String] The format identifier
      # @return [Proc, Object] Strategy for the format
      def get_strategy(format)
        @strategies[format.to_s] || @strategies["console"]
      end

      # Check if a format is registered
      # @param format [String] The format identifier
      # @return [Boolean] True if format is registered
      def registered?(format)
        @strategies.key?(format.to_s)
      end

      # List all registered formats
      # @return [Array<String>] List of registered format names
      def registered_formats
        @strategies.keys
      end

      private

      def register_default_strategies
        # Register strategies for each supported format
        register("dot", ->(result, _options) { result.to_dot })
        register("json", ->(result, _options) { result.to_json })
        register("html", ->(result, _options) { result.to_html })
        register("csv", ->(result, _options) { result.to_csv })
        register("console", method(:console_strategy))
      end

      # Console strategy with options support
      def console_strategy(result, options = {})
        output = result.to_console

        if options[:include_stats]
          output += format_statistics(result.statistics)
        end

        if options[:include_circular]
          output += format_circular_dependencies(result.circular_dependencies)
        end

        if options[:include_depth]
          output += format_dependency_depth(result.dependency_depth)
        end

        output
      end

      # Delegate to OutputWriter static methods for consistency
      def format_statistics(stats)
        RailsDependencyExplorer::CLI::OutputWriter.format_statistics(stats)
      end

      def format_circular_dependencies(cycles)
        RailsDependencyExplorer::CLI::OutputWriter.format_circular_dependencies(cycles)
      end

      def format_dependency_depth(depths)
        RailsDependencyExplorer::CLI::OutputWriter.format_dependency_depth(depths)
      end
    end
  end
end
