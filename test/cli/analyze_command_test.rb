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
    Tempfile.create(["test", ".rb"]) do |file|
      file.write("class TestClass\n  def initialize\n    @logger = Logger.new\n  end\nend")
      file.flush

      parser = RailsDependencyExplorer::CLI::ArgumentParser.new(["analyze", file.path])
      command = RailsDependencyExplorer::CLI::AnalyzeCommand.new(parser, @output_writer)

      output = capture_io do
        result = command.execute
        assert_equal 0, result
      end

      assert_includes output[0], "Dependencies found:"
      assert_includes output[0], "TestClass"
    end
  end

  def test_execute_returns_error_for_missing_file_path
    parser = RailsDependencyExplorer::CLI::ArgumentParser.new(["analyze"])
    command = RailsDependencyExplorer::CLI::AnalyzeCommand.new(parser, @output_writer)

    output = capture_io do
      result = command.execute
      assert_equal 1, result
    end

    assert_includes output[0], "Error: analyze command requires a file path"
  end

  def test_execute_returns_error_for_nonexistent_file
    parser = RailsDependencyExplorer::CLI::ArgumentParser.new(["analyze", "/nonexistent/file.rb"])
    command = RailsDependencyExplorer::CLI::AnalyzeCommand.new(parser, @output_writer)

    output = capture_io do
      result = command.execute
      assert_equal 1, result
    end

    assert_includes output[0], "Error: File not found: /nonexistent/file.rb"
  end

  def test_execute_analyzes_directory_when_directory_option_present
    Dir.mktmpdir do |dir|
      # Create a test Ruby file in the directory
      test_file = File.join(dir, "test_class.rb")
      File.write(test_file, "class TestClass\n  def initialize\n    @logger = Logger.new\n  end\nend")

      parser = RailsDependencyExplorer::CLI::ArgumentParser.new(["analyze", "--directory", dir])
      command = RailsDependencyExplorer::CLI::AnalyzeCommand.new(parser, @output_writer)

      output = capture_io do
        result = command.execute
        assert_equal 0, result
      end

      assert_includes output[0], "Dependencies found:"
    end
  end

  def test_execute_returns_error_for_missing_directory_path
    parser = RailsDependencyExplorer::CLI::ArgumentParser.new(["analyze", "--directory"])
    command = RailsDependencyExplorer::CLI::AnalyzeCommand.new(parser, @output_writer)

    output = capture_io do
      result = command.execute
      assert_equal 1, result
    end

    assert_includes output[0], "Error: --directory option requires a directory path"
  end

  def test_execute_returns_error_for_nonexistent_directory
    parser = RailsDependencyExplorer::CLI::ArgumentParser.new(["analyze", "--directory", "/nonexistent/dir"])
    command = RailsDependencyExplorer::CLI::AnalyzeCommand.new(parser, @output_writer)

    output = capture_io do
      result = command.execute
      assert_equal 1, result
    end

    assert_includes output[0], "Error: Directory not found: /nonexistent/dir"
  end

  def test_execute_respects_format_option
    Tempfile.create(["test", ".rb"]) do |file|
      file.write("class TestClass\n  def initialize\n    @logger = Logger.new\n  end\nend")
      file.flush

      parser = RailsDependencyExplorer::CLI::ArgumentParser.new(["analyze", file.path, "--format", "json"])
      command = RailsDependencyExplorer::CLI::AnalyzeCommand.new(parser, @output_writer)

      output = capture_io do
        result = command.execute
        assert_equal 0, result
      end

      assert_includes output[0], '"dependencies"'
      assert_includes output[0], '"TestClass"'
    end
  end

  def test_execute_writes_to_output_file_when_specified
    Tempfile.create(["test", ".rb"]) do |file|
      file.write("class TestClass\n  def initialize\n    @logger = Logger.new\n  end\nend")
      file.flush

      Tempfile.create("output") do |output_file|
        parser = RailsDependencyExplorer::CLI::ArgumentParser.new([
          "analyze", file.path, "--format", "json", "--output", output_file.path
        ])
        command = RailsDependencyExplorer::CLI::AnalyzeCommand.new(parser, @output_writer)

        output = capture_io do
          result = command.execute
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
    Tempfile.create(["test", ".rb"]) do |file|
      file.write("class TestClass\nend")
      file.flush

      parser = RailsDependencyExplorer::CLI::ArgumentParser.new(["analyze", file.path, "--format", "invalid"])
      command = RailsDependencyExplorer::CLI::AnalyzeCommand.new(parser, @output_writer)

      output = capture_io do
        result = command.execute
        assert_equal 1, result
      end

      assert_includes output[0], "Error: Unsupported format 'invalid'"
    end
  end

  def test_execute_returns_error_for_invalid_output_option
    Tempfile.create(["test", ".rb"]) do |file|
      file.write("class TestClass\nend")
      file.flush

      parser = RailsDependencyExplorer::CLI::ArgumentParser.new(["analyze", file.path, "--output"])
      command = RailsDependencyExplorer::CLI::AnalyzeCommand.new(parser, @output_writer)

      output = capture_io do
        result = command.execute
        assert_equal 1, result
      end

      assert_includes output[0], "Error: --output option requires a file path"
    end
  end

  private

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
