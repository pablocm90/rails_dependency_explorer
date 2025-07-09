# frozen_string_literal: true

require "minitest/autorun"
require_relative "../../lib/rails_dependency_explorer/cli/argument_parser"

class ArgumentParserTest < Minitest::Test
  def test_parse_format_option_returns_default_when_no_format_specified
    parser = RailsDependencyExplorer::CLI::ArgumentParser.new(["analyze", "file.rb"])
    assert_equal "graph", parser.parse_format_option
  end

  def test_parse_format_option_returns_specified_format
    parser = RailsDependencyExplorer::CLI::ArgumentParser.new(["analyze", "file.rb", "--format", "json"])
    assert_equal "json", parser.parse_format_option
  end

  def test_parse_format_option_returns_nil_for_invalid_format
    parser = RailsDependencyExplorer::CLI::ArgumentParser.new(["analyze", "file.rb", "--format", "invalid"])

    output = capture_io do
      result = parser.parse_format_option
      assert_nil result
    end

    assert_includes output[0], "Error: Unsupported format 'invalid'"
    assert_includes output[0], "Supported formats: dot, json, html, graph"
  end

  def test_parse_format_option_returns_nil_when_format_value_missing
    parser = RailsDependencyExplorer::CLI::ArgumentParser.new(["analyze", "file.rb", "--format"])

    output = capture_io do
      result = parser.parse_format_option
      assert_nil result
    end

    assert_includes output[0], "Error: --format option requires a format value"
  end

  def test_parse_output_option_returns_nil_when_no_output_specified
    parser = RailsDependencyExplorer::CLI::ArgumentParser.new(["analyze", "file.rb"])
    assert_nil parser.parse_output_option
  end

  def test_parse_output_option_returns_specified_file
    parser = RailsDependencyExplorer::CLI::ArgumentParser.new(["analyze", "file.rb", "--output", "result.json"])
    assert_equal "result.json", parser.parse_output_option
  end

  def test_parse_output_option_returns_error_when_file_path_missing
    parser = RailsDependencyExplorer::CLI::ArgumentParser.new(["analyze", "file.rb", "--output"])

    output = capture_io do
      result = parser.parse_output_option
      assert_equal :error, result
    end

    assert_includes output[0], "Error: --output option requires a file path"
  end

  def test_has_directory_option_returns_true_when_present
    parser = RailsDependencyExplorer::CLI::ArgumentParser.new(["analyze", "--directory", "app/"])
    assert parser.has_directory_option?
  end

  def test_has_directory_option_returns_false_when_absent
    parser = RailsDependencyExplorer::CLI::ArgumentParser.new(["analyze", "file.rb"])
    refute parser.has_directory_option?
  end

  def test_get_directory_path_returns_path_when_present
    parser = RailsDependencyExplorer::CLI::ArgumentParser.new(["analyze", "--directory", "app/models"])
    assert_equal "app/models", parser.get_directory_path
  end

  def test_get_directory_path_returns_nil_when_no_directory_option
    parser = RailsDependencyExplorer::CLI::ArgumentParser.new(["analyze", "file.rb"])
    assert_nil parser.get_directory_path
  end

  def test_get_directory_path_returns_nil_when_path_missing
    parser = RailsDependencyExplorer::CLI::ArgumentParser.new(["analyze", "--directory"])
    assert_nil parser.get_directory_path
  end

  def test_get_file_path_returns_file_when_present
    parser = RailsDependencyExplorer::CLI::ArgumentParser.new(["analyze", "app/models/user.rb"])
    assert_equal "app/models/user.rb", parser.get_file_path
  end

  def test_get_file_path_returns_nil_when_missing
    parser = RailsDependencyExplorer::CLI::ArgumentParser.new(["analyze"])
    assert_nil parser.get_file_path
  end

  def test_has_help_option_returns_true_for_help_flag
    parser = RailsDependencyExplorer::CLI::ArgumentParser.new(["--help"])
    assert parser.has_help_option?
  end

  def test_has_help_option_returns_true_for_h_flag
    parser = RailsDependencyExplorer::CLI::ArgumentParser.new(["-h"])
    assert parser.has_help_option?
  end

  def test_has_help_option_returns_true_for_empty_args
    parser = RailsDependencyExplorer::CLI::ArgumentParser.new([])
    assert parser.has_help_option?
  end

  def test_has_help_option_returns_false_for_normal_command
    parser = RailsDependencyExplorer::CLI::ArgumentParser.new(["analyze", "file.rb"])
    refute parser.has_help_option?
  end

  def test_has_version_option_returns_true_when_present
    parser = RailsDependencyExplorer::CLI::ArgumentParser.new(["--version"])
    assert parser.has_version_option?
  end

  def test_has_version_option_returns_false_when_absent
    parser = RailsDependencyExplorer::CLI::ArgumentParser.new(["analyze", "file.rb"])
    refute parser.has_version_option?
  end

  def test_get_command_returns_first_argument
    parser = RailsDependencyExplorer::CLI::ArgumentParser.new(["analyze", "file.rb"])
    assert_equal "analyze", parser.get_command
  end

  def test_get_command_returns_nil_for_empty_args
    parser = RailsDependencyExplorer::CLI::ArgumentParser.new([])
    assert_nil parser.get_command
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
