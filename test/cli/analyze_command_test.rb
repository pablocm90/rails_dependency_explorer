# frozen_string_literal: true

require "minitest/autorun"
require "tempfile"
require_relative "../../lib/rails_dependency_explorer/cli/analyze_command"
require_relative "../../lib/rails_dependency_explorer/cli/argument_parser"
require_relative "../../lib/rails_dependency_explorer/cli/output_writer"

class AnalyzeCommandTest < Minitest::Test
  def setup
    @output_writer = RailsDependencyExplorer::CLI::OutputWriter.new
  end

  def test_execute_analyzes_single_file_successfully
    with_test_file do |file|
      command = create_analyze_command(["analyze", file.path])

      output = execute_command_with_capture(command) do |result|
        assert_equal 0, result
      end

      assert_includes output[0], "Dependencies found:"
      assert_includes output[0], "TestClass"
    end
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

  def test_execute_writes_to_output_file_when_specified
    with_test_file do |file|
      with_output_file do |output_file|
        command = create_analyze_command([
          "analyze", file.path, "--format", "json", "--output", output_file.path
        ])

        output = execute_command_with_capture(command) do |result|
          assert_equal 0, result
        end

        # Should not output to stdout
        assert_empty output[0]

        # Should write to file
        file_content = File.read(output_file.path)
        assert_includes file_content, '"dependencies"'
        assert_includes file_content, '"TestClass"'
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

  private

  def with_test_file(content = "class TestClass\n  def initialize\n    @logger = Logger.new\n  end\nend")
    Tempfile.create(["test", ".rb"]) do |file|
      file.write(content)
      file.flush
      yield file
    end
  end

  def with_test_directory
    Dir.mktmpdir do |dir|
      # Create a test Ruby file in the directory
      test_file = File.join(dir, "test_class.rb")
      File.write(test_file, "class TestClass\n  def initialize\n    @logger = Logger.new\n  end\nend")
      yield dir
    end
  end

  def with_output_file
    Tempfile.create("output") do |output_file|
      yield output_file
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

  def capture_io
    original_stdout = $stdout
    original_stderr = $stderr
    $stdout = StringIO.new
    $stderr = StringIO.new

    yield

    [$stdout.string, $stderr.string]
  ensure
    $stdout = original_stdout
    $stderr = original_stderr
  end
end
