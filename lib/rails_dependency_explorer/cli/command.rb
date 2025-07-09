# frozen_string_literal: true

require_relative "argument_parser"
require_relative "output_writer"
require_relative "analyze_command"
require_relative "help_display"

module RailsDependencyExplorer
  module CLI
    class Command
      def initialize(args)
        @args = args
        @parser = ArgumentParser.new(args)
        @output_writer = OutputWriter.new
        @help_display = HelpDisplay.new
      end

      def run
        if @parser.has_help_option?
          @help_display.display_help
          return 0
        end

        if @parser.has_version_option?
          @help_display.display_version
          return 0
        end

        if @parser.get_command == "analyze"
          analyze_cmd = AnalyzeCommand.new(@parser, @output_writer)
          return analyze_cmd.execute
        end

        # Default case - show help for unknown commands
        @help_display.display_help
        0
      end
    end
  end
end
