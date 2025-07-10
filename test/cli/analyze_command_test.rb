# frozen_string_literal: true

require "minitest/autorun"
require_relative "../test_helper"
require_relative "../support/file_test_helpers"
require_relative "../../lib/rails_dependency_explorer/cli/analyze_command"
require_relative "../../lib/rails_dependency_explorer/cli/argument_parser"
require_relative "../../lib/rails_dependency_explorer/cli/output_writer"

class AnalyzeCommandTest < Minitest::Test
  include IOTestHelpers
  def setup
    @output_writer = RailsDependencyExplorer::CLI::OutputWriter.new
  end

  def test_execute_returns_error_for_missing_file_path
    command = create_analyze_command(["analyze"])

    output = execute_command_with_capture(command) do |result|
      assert_equal 1, result
    end

    assert_includes output[0], "Error: analyze command requires a file path"
  end

  def test_execute_returns_error_for_nonexistent_file
    command = create_analyze_command(["analyze", "/nonexistent/file.rb"])

    output = execute_command_with_capture(command) do |result|
      assert_equal 1, result
    end

    assert_includes output[0], "Error: File not found: /nonexistent/file.rb"
  end

  def test_execute_analyzes_directory_when_directory_option_present
    with_test_directory do |dir|
      command = create_analyze_command(["analyze", "--directory", dir])

      output = execute_command_with_capture(command) do |result|
        assert_equal 0, result
      end

      assert_includes output[0], "Dependencies found:"
    end
  end

  def test_execute_returns_error_for_missing_directory_path
    command = create_analyze_command(["analyze", "--directory"])

    output = execute_command_with_capture(command) do |result|
      assert_equal 1, result
    end

    assert_includes output[0], "Error: --directory option requires a directory path"
  end

  def test_execute_returns_error_for_nonexistent_directory
    command = create_analyze_command(["analyze", "--directory", "/nonexistent/dir"])

    output = execute_command_with_capture(command) do |result|
      assert_equal 1, result
    end

    assert_includes output[0], "Error: Directory not found: /nonexistent/dir"
  end

  def test_execute_respects_format_option
    with_test_file do |file|
      command = create_analyze_command(["analyze", file.path, "--format", "json"])

      output = execute_command_with_capture(command) do |result|
        assert_equal 0, result
      end

      assert_includes output[0], '"dependencies"'
      assert_includes output[0], '"TestClass"'
    end
  end

  def test_execute_succeeds_with_output_file_option
    with_test_file do |file|
      with_output_file do |output_file|
        command = create_analyze_command([
          "analyze", file.path, "--format", "json", "--output", output_file.path
        ])

        result = command.execute
        assert_equal 0, result
      end
    end
  end

  def test_execute_writes_content_to_specified_output_file
    with_test_file do |file|
      with_output_file do |output_file|
        command = create_analyze_command([
          "analyze", file.path, "--format", "json", "--output", output_file.path
        ])

        command.execute
        file_content = File.read(output_file.path)
        assert_includes file_content, '"dependencies"'
        assert_includes file_content, '"TestClass"'
      end
    end
  end

  def test_execute_suppresses_stdout_when_output_file_specified
    with_test_file do |file|
      with_output_file do |output_file|
        command = create_analyze_command([
          "analyze", file.path, "--format", "json", "--output", output_file.path
        ])

        output = execute_command_with_capture(command)
        assert_empty output[0]
      end
    end
  end

  def test_execute_returns_error_for_invalid_format
    with_test_file("class TestClass\nend") do |file|
      command = create_analyze_command(["analyze", file.path, "--format", "invalid"])

      output = execute_command_with_capture(command) do |result|
        assert_equal 1, result
      end

      assert_includes output[0], "Error: Invalid format 'invalid'"
    end
  end

  def test_execute_returns_error_for_invalid_output_option
    with_test_file("class TestClass\nend") do |file|
      command = create_analyze_command(["analyze", file.path, "--output"])

      output = execute_command_with_capture(command) do |result|
        assert_equal 1, result
      end

      assert_includes output[0], "Error: --output option requires a file path"
    end
  end

  def test_error_handling_consistency_between_file_and_directory_analysis
    # Test that both file and directory analysis use consistent error handling
    # This test will help ensure error handling extraction maintains consistency

    # Test file analysis error handling
    command = create_analyze_command(["analyze", "/nonexistent/file.rb"])
    file_output = execute_command_with_capture(command) { |result| assert_equal 1, result }

    # Test directory analysis error handling
    command = create_analyze_command(["analyze", "--directory", "/nonexistent/dir"])
    dir_output = execute_command_with_capture(command) { |result| assert_equal 1, result }

    # Both should follow same error message pattern: "Error: " prefix
    assert_match(/^Error: /, file_output[0])
    assert_match(/^Error: /, dir_output[0])
  end

  def test_analysis_coordination_follows_same_pattern_for_file_and_directory
    # Test that both file and directory analysis follow the same coordination pattern:
    # 1. Get path, 2. Validate path, 3. Parse options, 4. Perform analysis
    # This test ensures refactoring maintains the consistent flow

    with_test_file do |file|
      # Test successful file analysis follows expected pattern
      command = create_analyze_command(["analyze", file.path, "--format", "json"])
      output = execute_command_with_capture(command) do |result|
        assert_equal 0, result  # Should succeed
      end
      assert_includes output[0], '"dependencies"'
    end

    with_test_directory do |dir|
      # Test successful directory analysis follows expected pattern
      command = create_analyze_command(["analyze", "--directory", dir, "--format", "json"])
      output = execute_command_with_capture(command) do |result|
        assert_equal 0, result  # Should succeed
      end
      assert_includes output[0], '"dependencies"'
    end
  end

  private

  def with_test_directory
    Dir.mktmpdir do |dir|
      # Create a test Ruby file in the directory using shared helper
      create_ruby_file(dir, "test_class.rb", default_test_class_content)
      yield dir
    end
  end

  def create_analyze_command(args)
    parser = RailsDependencyExplorer::CLI::ArgumentParser.new(args)
    RailsDependencyExplorer::CLI::AnalyzeCommand.new(parser, @output_writer)
  end

  def execute_command_with_capture(command)
    capture_io do
      result = command.execute
      yield result if block_given?
    end
  end
end
