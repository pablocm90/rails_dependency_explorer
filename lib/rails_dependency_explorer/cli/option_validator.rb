# frozen_string_literal: true

module RailsDependencyExplorer
  module CLI
    # Handles validation of command-line option values.
    # Separates validation logic from option extraction and error handling,
    # following SRP. Extracted from ArgumentParser as part of H5 refactoring.
    class OptionValidator
      VALID_FORMATS = ["dot", "json", "html", "graph"].freeze

      def validate_format(format_value)
        case format_value
        when nil
          { valid: true, value: "graph", error: nil }  # Default format
        when :missing
          { valid: false, value: nil, error: format_missing_error }
        else
          validate_format_value(format_value)
        end
      end

      def validate_output(output_value)
        case output_value
        when nil
          { valid: true, value: nil, error: nil }  # No output file specified
        when :missing
          { valid: false, value: nil, error: output_missing_error }
        else
          { valid: true, value: output_value, error: nil }
        end
      end

      def validate_directory(directory_value)
        case directory_value
        when nil
          { valid: true, value: nil, error: nil }  # No directory specified
        when :missing
          { valid: false, value: nil, error: directory_missing_error }
        else
          { valid: true, value: directory_value, error: nil }
        end
      end

      private

      def validate_format_value(format)
        if VALID_FORMATS.include?(format)
          { valid: true, value: format, error: nil }
        else
          { valid: false, value: nil, error: format_invalid_error(format) }
        end
      end

      def format_missing_error
        {
          message: "Error: --format option requires a format value",
          details: "Supported formats: #{VALID_FORMATS.join(", ")}"
        }
      end

      def format_invalid_error(format)
        {
          message: "Error: Invalid format '#{format}'",
          details: "Supported formats: #{VALID_FORMATS.join(", ")}"
        }
      end

      def output_missing_error
        {
          message: "Error: --output option requires a file path",
          details: nil
        }
      end

      def directory_missing_error
        {
          message: "Error: --directory option requires a directory path",
          details: nil
        }
      end
    end
  end
end
