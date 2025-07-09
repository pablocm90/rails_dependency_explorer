# frozen_string_literal: true

require_relative "../version"

module RailsDependencyExplorer
  module CLI
    class Command
      def initialize(args)
        @args = args
      end

      def run
        if @args.empty? || @args.include?("--help") || @args.include?("-h")
          display_help
          return 0
        end

        if @args.include?("--version")
          display_version
          return 0
        end

        # Default case - for now just show help
        display_help
        0
      end

      private

      def display_help
        puts <<~HELP
          Usage: rails_dependency_explorer analyze <path> [options]

          Commands:
            analyze <path>           Analyze Ruby files for dependencies

          Options:
            --format, -f FORMAT      Output format: dot, json, html, graph (default: graph)
            --output, -o FILE        Write output to file instead of stdout
            --directory, -d          Treat path as directory to scan
            --pattern, -p PATTERN    File pattern for directory scanning (default: "*.rb")
            --stats, -s              Include dependency statistics
            --circular, -c           Include circular dependency analysis
            --depth                  Include dependency depth analysis
            --verbose, -v            Verbose output
            --quiet, -q              Quiet mode (minimal output)
            --config CONFIG_FILE     Load configuration from file
            --help, -h               Show this help message
            --version                Show version information

          Examples:
            rails_dependency_explorer analyze app/models/user.rb
            rails_dependency_explorer analyze app/ --format html --output report.html
            rails_dependency_explorer analyze app/models --pattern "*_service.rb" --stats --circular
            rails_dependency_explorer analyze . --format dot --output dependencies.dot --verbose
        HELP
      end

      def display_version
        puts RailsDependencyExplorer::VERSION
      end
    end
  end
end
