# frozen_string_literal: true

module RailsDependencyExplorer
  module CLI
    class ArgumentParser
      def initialize(args)
        @args = args
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
          puts "Error: Invalid format '#{format}'"
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

      def has_directory_option?
        @args.include?("--directory")
      end

      def get_directory_path
        directory_index = @args.index("--directory")
        return nil if directory_index.nil? || directory_index + 1 >= @args.length
        @args[directory_index + 1]
      end

      def get_file_path
        return nil if @args.length < 2
        @args[1]
      end

      def has_help_option?
        @args.empty? || @args.include?("--help") || @args.include?("-h")
      end

      def has_version_option?
        @args.include?("--version")
      end

      def get_command
        return nil if @args.empty?
        @args[0]
      end

      def has_stats_option?
        @args.include?("--stats") || @args.include?("-s")
      end

      def has_circular_option?
        @args.include?("--circular") || @args.include?("-c")
      end

      def has_depth_option?
        @args.include?("--depth")
      end
    end
  end
end
