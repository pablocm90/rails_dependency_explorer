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
        return execute_help_command if @parser.has_help_option?
        return handle_version_option if @parser.has_version_option?

        command = @parser.get_command
        execute_command(command)
      end

      private

      def handle_version_option
        @help_display.display_version
        0
      end

      def execute_command(command)
        case command
        when "analyze"
          execute_analyze_command
        when nil
          execute_help_command
        else
          execute_unknown_command(command)
        end
      end

      private

      def execute_analyze_command
        analyze_cmd = AnalyzeCommand.new(@parser, @output_writer)
        analyze_cmd.execute
      end

      def execute_help_command
        @help_display.display_help
        0
      end

      def execute_unknown_command(command)
        display_error("Unknown command '#{command}'")
        1
      end

      def display_error(message)
        puts "Error: #{message}"
      end
    end
  end
end
