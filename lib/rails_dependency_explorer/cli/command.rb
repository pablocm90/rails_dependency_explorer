# frozen_string_literal: true

require_relative "../version"
require_relative "../analysis/dependency_explorer"

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

        if @args[0] == "analyze"
          return analyze_command
        end

        # Default case - show help for unknown commands
        display_help
        0
      end

      private

      def analyze_command
        # Check for directory analysis option
        if @args.include?("--directory")
          return analyze_directory_command
        end

        if @args.length < 2
          puts "Error: analyze command requires a file path"
          puts "Usage: rails_dependency_explorer analyze <path>"
          return 1
        end

        file_path = @args[1]

        unless File.exist?(file_path)
          puts "Error: File not found: #{file_path}"
          return 1
        end

        begin
          ruby_code = File.read(file_path)
          explorer = Analysis::DependencyExplorer.new
          result = explorer.analyze_code(ruby_code)

          # Output in default format (console)
          puts result.to_console

          return 0
        rescue => e
          puts "Error analyzing file: #{e.message}"
          return 1
        end
      end

      def analyze_directory_command
        directory_index = @args.index("--directory")

        if directory_index.nil? || directory_index + 1 >= @args.length
          puts "Error: --directory option requires a directory path"
          return 1
        end

        directory_path = @args[directory_index + 1]

        unless File.directory?(directory_path)
          puts "Error: Directory not found: #{directory_path}"
          return 1
        end

        begin
          explorer = Analysis::DependencyExplorer.new
          result = explorer.analyze_directory(directory_path)

          # Output in default format (console)
          puts result.to_console

          return 0
        rescue => e
          puts "Error analyzing directory: #{e.message}"
          return 1
        end
      end

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
