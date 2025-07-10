# frozen_string_literal: true

module RailsDependencyExplorer
  module CLI
    # Handles detection of boolean flags in command-line arguments.
    # Separates flag detection concerns from option parsing and validation,
    # following SRP. Extracted from ArgumentParser as part of H5 refactoring.
    class FlagDetector
      def initialize(args)
        @args = args
      end

      def has_help_flag?
        @args.empty? || @args.include?("--help") || @args.include?("-h")
      end

      def has_version_flag?
        @args.include?("--version")
      end

      def has_directory_flag?
        @args.include?("--directory")
      end

      def has_stats_flag?
        @args.include?("--stats") || @args.include?("-s")
      end

      def has_circular_flag?
        @args.include?("--circular") || @args.include?("-c")
      end

      def has_depth_flag?
        @args.include?("--depth") || @args.include?("-d")
      end

      def has_any_flag?(*flag_names)
        flag_names.any? { |flag| @args.include?(flag) }
      end
    end
  end
end
