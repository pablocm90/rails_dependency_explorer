# frozen_string_literal: true

require "minitest/autorun"
require_relative "../test_helper"
require_relative "../support/file_test_helpers"
require_relative "../../lib/rails_dependency_explorer/cli/output_writer"
require_relative "../../lib/rails_dependency_explorer/analysis/pipeline/analysis_result"

class OutputWriterTest < Minitest::Test
  include IOTestHelpers
  def setup
    @writer = RailsDependencyExplorer::CLI::OutputWriter.new
    @result = create_sample_result
  end

  def test_write_output_to_stdout_when_no_file_specified
    output = capture_io do
      @writer.write_output("test content", nil)
    end

    assert_equal "test content\n", output[0]
  end

  def test_write_output_to_file_when_file_specified
    with_output_file do |file|
      @writer.write_output("test content", file.path)

      assert_equal "test content", File.read(file.path)
    end
  end

  def test_write_output_raises_error_for_invalid_file_path
    output = capture_io do
      assert_raises(Errno::ENOENT) do
        @writer.write_output("test content", "/invalid/path/file.txt")
      end
    end

    assert_includes output[0], "Error writing to file '/invalid/path/file.txt'"
  end

  def test_format_output_returns_html_format
    assert_format_output_includes("html", ["<!DOCTYPE html>", "Dependencies Report"])
  end

  def test_format_output_returns_graph_format
    assert_format_output_includes("graph", ["Dependencies found:", "SampleClass"])
  end

  def test_format_output_returns_graph_format_for_unknown_format
    assert_format_output_includes("unknown", ["Dependencies found:", "SampleClass"])
  end

  def test_format_output_returns_csv_format
    assert_format_output_includes("csv", ["Source,Target,Methods", "SampleClass,Logger"])
  end

  def test_format_output_handles_all_supported_formats
    formats = ["dot", "json", "html", "csv", "graph"]

    formats.each do |format|
      result = @writer.format_output(@result, format)
      refute_empty result
      assert_kind_of String, result
    end
  end

  private

  def create_sample_result
    # Create proper structure: class_name => [{dependency => [methods]}]
    dependencies = {
      "SampleClass" => [
        {"Logger" => ["new"]},
        {"DataValidator" => ["validate"]}
      ]
    }
    RailsDependencyExplorer::Analysis::Pipeline::AnalysisResult.new(dependencies)
  end

  def assert_format_output_includes(format, expected_content)
    result = @writer.format_output(@result, format)
    if expected_content.is_a?(Array)
      expected_content.each { |content| assert_includes result, content }
    else
      assert_includes result, expected_content
    end
  end
end
