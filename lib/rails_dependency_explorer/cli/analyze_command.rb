# frozen_string_literal: true

require_relative "../analysis/dependency_explorer"

module RailsDependencyExplorer
  module CLI
    class AnalyzeCommand
      def initialize(parser, output_writer)
        @parser = parser
        @output_writer = output_writer
      end

      def execute
        # Check for directory analysis option
        if @parser.has_directory_option?
          return analyze_directory
        end

        analyze_file
      end

      private

      def analyze_file
        file_path = @parser.get_file_path
        if file_path.nil?
          puts "Error: analyze command requires a file path"
          puts "Usage: rails_dependency_explorer analyze <path>"
          return 1
        end

        unless File.exist?(file_path)
          puts "Error: File not found: #{file_path}"
          return 1
        end

        # Parse format option
        format = @parser.parse_format_option
        return 1 if format.nil?

        # Parse output option
        output_file = @parser.parse_output_option
        return 1 if output_file == :error

        begin
          ruby_code = File.read(file_path)
          explorer = Analysis::DependencyExplorer.new
          result = explorer.analyze_code(ruby_code)

          # Output in specified format
          output_content = @output_writer.format_output(result, format)
          @output_writer.write_output(output_content, output_file)

          0
        rescue => e
          puts "Error analyzing file: #{e.message}"
          1
        end
      end

      def analyze_directory
        directory_path = @parser.get_directory_path

        if directory_path.nil?
          puts "Error: --directory option requires a directory path"
          return 1
        end

        unless File.directory?(directory_path)
          puts "Error: Directory not found: #{directory_path}"
          return 1
        end

        # Parse format option
        format = @parser.parse_format_option
        return 1 if format.nil?

        # Parse output option
        output_file = @parser.parse_output_option
        return 1 if output_file == :error

        begin
          explorer = Analysis::DependencyExplorer.new
          result = explorer.analyze_directory(directory_path)

          # Output in specified format
          output_content = @output_writer.format_output(result, format)
          @output_writer.write_output(output_content, output_file)

          0
        rescue => e
          puts "Error analyzing directory: #{e.message}"
          1
        end
      end
    end
  end
end
