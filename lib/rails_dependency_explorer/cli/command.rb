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

        # Parse format option
        format = parse_format_option
        return 1 if format.nil?

        # Parse output option
        output_file = parse_output_option
        return 1 if output_file == :error

        begin
          ruby_code = File.read(file_path)
          explorer = Analysis::DependencyExplorer.new
          result = explorer.analyze_code(ruby_code)

          # Output in specified format
          output_content = format_output(result, format)
          write_output(output_content, output_file)

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

        # Parse format option
        format = parse_format_option
        return 1 if format.nil?

        # Parse output option
        output_file = parse_output_option
        return 1 if output_file == :error

        begin
          explorer = Analysis::DependencyExplorer.new
          result = explorer.analyze_directory(directory_path)

          # Output in specified format
          output_content = format_output(result, format)
          write_output(output_content, output_file)

          return 0
        rescue => e
          puts "Error analyzing directory: #{e.message}"
          return 1
        end
      end

      def parse_format_option
        format_index = @args.index("--format")

        # Default format if no --format option provided
        return "graph" if format_index.nil?

        # Check if format value is provided
        if format_index + 1 >= @args.length
          puts "Error: --format option requires a format value"
          puts "Supported formats: dot, json, html, graph"
          return nil
        end

        format = @args[format_index + 1]
        valid_formats = ["dot", "json", "html", "graph"]

        unless valid_formats.include?(format)
          puts "Error: Unsupported format '#{format}'"
          puts "Supported formats: #{valid_formats.join(', ')}"
          return nil
        end

        format
      end

      def parse_output_option
        output_index = @args.index("--output")

        # No output file specified, use stdout
        return nil if output_index.nil?

        # Check if output file path is provided
        if output_index + 1 >= @args.length
          puts "Error: --output option requires a file path"
          return :error
        end

        @args[output_index + 1]
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

      def format_output(result, format)
        case format
        when "dot"
          result.to_dot
        when "json"
          result.to_json
        when "html"
          result.to_html
        when "graph"
          result.to_console
        else
          result.to_console
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
