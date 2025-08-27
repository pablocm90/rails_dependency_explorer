# frozen_string_literal: true

require_relative 'option_extractor'
require_relative 'option_validator'
require_relative 'flag_detector'

module RailsDependencyExplorer
  module CLI
    # Coordinates command-line argument parsing by delegating to specialized classes.
    # Refactored from complex mixed-concern implementation to follow SRP.
    #
    # Responsibilities:
    # - Coordinates between OptionExtractor, OptionValidator, and FlagDetector
    # - Provides unified interface for command-line argument access
    # - Handles error message formatting and display
    #
    # Part of H5 refactoring to separate option parsing concerns.
    class ArgumentParser
      def initialize(args)
        @args = args
        @extractor = OptionExtractor.new(args)
        @validator = OptionValidator.new
        @flag_detector = FlagDetector.new(args)
      end

      def parse_format_option
        format_value = @extractor.extract_format_option
        validation_result = @validator.validate_format(format_value)
        handle_validation_result(validation_result, nil)
      end

      private

      def handle_validation_result(validation_result, error_return_value)
        if validation_result[:valid]
          validation_result[:value]
        else
          print_validation_error(validation_result[:error])
          error_return_value
        end
      end

      def print_validation_error(error)
        puts error[:message]
        puts error[:details] if error.key?(:details) && error[:details]
      end

      public

      def parse_output_option
        output_value = @extractor.extract_output_option
        validation_result = @validator.validate_output(output_value)
        handle_validation_result(validation_result, :error)
      end

      def has_help_option?
        @flag_detector.has_help_flag?
      end

      def has_version_option?
        @flag_detector.has_version_flag?
      end

      def get_command
        @extractor.get_command
      end

      def get_file_path
        @extractor.get_file_path
      end

      def has_directory_option?
        @flag_detector.has_directory_flag?
      end

      def get_directory_path
        directory_value = @extractor.extract_directory_option
        validation_result = @validator.validate_directory(directory_value)
        handle_validation_result(validation_result, nil)
      end

      def has_stats_option?
        @flag_detector.has_stats_flag?
      end

      def has_circular_option?
        @flag_detector.has_circular_flag?
      end

      def has_depth_option?
        @flag_detector.has_depth_flag?
      end


    end
  end
end
