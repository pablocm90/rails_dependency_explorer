# frozen_string_literal: true

require "minitest/autorun"
require_relative "../support/file_test_helpers"
require_relative "../../lib/rails_dependency_explorer/cli/argument_parser"

class ArgumentParserTest < Minitest::Test
  include IOTestHelpers
  def test_parse_format_option_returns_default_when_no_format_specified
    assert_parser_method_result(["analyze", "file.rb"], :parse_format_option, "graph")
  end

  def test_parse_format_option_returns_specified_format
    assert_parser_method_result(["analyze", "file.rb", "--format", "json"], :parse_format_option, "json")
  end

  def test_parse_format_option_returns_nil_for_invalid_format
    assert_parser_method_with_output(
      ["analyze", "file.rb", "--format", "invalid"],
      :parse_format_option,
      nil,
      ["Error: Invalid format 'invalid'", "Supported formats: dot, json, html, graph"]
    )
  end

  def test_parse_format_option_returns_nil_when_format_value_missing
    assert_parser_method_with_output(
      ["analyze", "file.rb", "--format"],
      :parse_format_option,
      nil,
      ["Error: --format option requires a format value"]
    )
  end

  def test_parse_output_option_returns_nil_when_no_output_specified
    assert_parser_method_result(["analyze", "file.rb"], :parse_output_option, nil)
  end

  def test_parse_output_option_returns_specified_file
    assert_parser_method_result(["analyze", "file.rb", "--output", "result.json"], :parse_output_option, "result.json")
  end

  def test_parse_output_option_returns_error_when_file_path_missing
    assert_parser_method_with_output(
      ["analyze", "file.rb", "--output"],
      :parse_output_option,
      :error,
      ["Error: --output option requires a file path"]
    )
  end

  def test_has_directory_option_returns_true_when_present
    parser = create_parser(["analyze", "--directory", "app/"])
    assert parser.has_directory_option?
  end

  def test_has_directory_option_returns_false_when_absent
    parser = create_parser(["analyze", "file.rb"])
    refute parser.has_directory_option?
  end

  def test_get_directory_path_returns_path_when_present
    assert_parser_method_result(["analyze", "--directory", "app/models"], :get_directory_path, "app/models")
  end

  def test_get_directory_path_returns_nil_when_no_directory_option
    assert_parser_method_result(["analyze", "file.rb"], :get_directory_path, nil)
  end

  def test_get_directory_path_returns_nil_when_path_missing
    assert_parser_method_result(["analyze", "--directory"], :get_directory_path, nil)
  end

  def test_get_file_path_returns_file_when_present
    assert_parser_method_result(["analyze", "app/models/user.rb"], :get_file_path, "app/models/user.rb")
  end

  def test_get_file_path_returns_nil_when_missing
    assert_parser_method_result(["analyze"], :get_file_path, nil)
  end

  def test_has_help_option_returns_true_for_help_flag
    parser = create_parser(["--help"])
    assert parser.has_help_option?
  end

  def test_has_help_option_returns_true_for_h_flag
    parser = create_parser(["-h"])
    assert parser.has_help_option?
  end

  def test_has_help_option_returns_true_for_empty_args
    parser = create_parser([])
    assert parser.has_help_option?
  end

  def test_has_help_option_returns_false_for_normal_command
    parser = create_parser(["analyze", "file.rb"])
    refute parser.has_help_option?
  end

  def test_has_version_option_returns_true_when_present
    parser = create_parser(["--version"])
    assert parser.has_version_option?
  end

  def test_has_version_option_returns_false_when_absent
    parser = create_parser(["analyze", "file.rb"])
    refute parser.has_version_option?
  end

  def test_get_command_returns_first_argument
    assert_parser_method_result(["analyze", "file.rb"], :get_command, "analyze")
  end

  def test_get_command_returns_nil_for_empty_args
    assert_parser_method_result([], :get_command, nil)
  end

  private

  def create_parser(args)
    RailsDependencyExplorer::CLI::ArgumentParser.new(args)
  end

  def assert_parser_method_result(args, method, expected_result)
    parser = create_parser(args)
    if expected_result.nil?
      assert_nil parser.send(method)
    else
      assert_equal expected_result, parser.send(method)
    end
  end

  def assert_parser_method_with_output(args, method, expected_result, expected_output_patterns)
    parser = create_parser(args)

    output = capture_io do
      result = parser.send(method)
      assert_equal expected_result, result
    end

    expected_output_patterns.each do |pattern|
      assert_includes output[0], pattern
    end
  end

end
