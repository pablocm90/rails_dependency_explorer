# frozen_string_literal: true

require_relative "../version"

module RailsDependencyExplorer
  module CLI
    class HelpDisplay
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
            --config CONFIG_FILE     Load configuration from file
            --help, -h               Show this help message
            --version                Show version information

          Examples:
            rails_dependency_explorer analyze app/models/user.rb
            rails_dependency_explorer analyze app/ --format html --output report.html
            rails_dependency_explorer analyze app/models --pattern "*_service.rb" --stats --circular
            rails_dependency_explorer analyze . --format dot --output dependencies.dot
        HELP
      end

      def display_version
        puts RailsDependencyExplorer::VERSION
      end
    end
  end
end
