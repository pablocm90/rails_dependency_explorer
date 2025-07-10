# frozen_string_literal: true

module RailsDependencyExplorer
  module CLI
    # Handles extraction of option values from command-line arguments.
    # Separates option extraction concerns from validation and error handling,
    # following SRP. Extracted from ArgumentParser as part of H5 refactoring.
    class OptionExtractor
      def initialize(args)
        @args = args
      end

      def extract_option_value(option_name)
        option_index = @args.index(option_name)
        return nil if option_index.nil?

        value_index = option_index + 1
        return :missing if value_index >= @args.length
        
        @args[value_index]
      end

      def extract_format_option
        extract_option_value("--format")
      end

      def extract_output_option
        extract_option_value("--output")
      end

      def extract_directory_option
        extract_option_value("--directory")
      end

      def get_command
        return nil if @args.empty?
        @args[0]
      end

      def get_file_path
        return nil if @args.length < 2
        @args[1]
      end

      def has_option?(option_name)
        @args.include?(option_name)
      end

      def has_any_option?(*option_names)
        option_names.any? { |option| @args.include?(option) }
      end
    end
  end
end
