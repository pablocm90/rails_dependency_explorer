# frozen_string_literal: true

require_relative "argument_parser"
require_relative "output_writer"
require_relative "analyze_command"
require_relative "help_display"

module RailsDependencyExplorer
  module CLI
    # Main command dispatcher for the Rails dependency explorer CLI.
    # Routes command-line arguments to appropriate command handlers (analyze, help)
    # and manages the overall CLI application flow and error handling.
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

        command = @parser.get_command

        case command
        when "analyze"
          analyze_cmd = AnalyzeCommand.new(@parser, @output_writer)
          analyze_cmd.execute
        when nil
          @help_display.display_help
          0
        else
          display_error("Unknown command '#{command}'")
          1
        end
      end

      private

      def display_error(message)
        puts "Error: #{message}"
      end
    end
  end
end
