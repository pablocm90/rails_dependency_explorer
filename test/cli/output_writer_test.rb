# frozen_string_literal: true

require "minitest/autorun"
require "tempfile"
require_relative "../../lib/rails_dependency_explorer/cli/output_writer"
require_relative "../../lib/rails_dependency_explorer/analysis/analysis_result"

class OutputWriterTest < Minitest::Test
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
    Tempfile.create("test_output") do |file|
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

  def test_format_output_returns_dot_format
    result = @writer.format_output(@result, "dot")
    assert_includes result, "digraph"
    assert_includes result, "SampleClass"
  end

  def test_format_output_returns_json_format
    result = @writer.format_output(@result, "json")
    assert_includes result, '"dependencies"'
    assert_includes result, '"SampleClass"'
  end

  def test_format_output_returns_html_format
    result = @writer.format_output(@result, "html")
    assert_includes result, "<!DOCTYPE html>"
    assert_includes result, "Dependencies Report"
  end

  def test_format_output_returns_graph_format
    result = @writer.format_output(@result, "graph")
    assert_includes result, "Dependencies found:"
    assert_includes result, "SampleClass"
  end

  def test_format_output_returns_graph_format_for_unknown_format
    result = @writer.format_output(@result, "unknown")
    assert_includes result, "Dependencies found:"
    assert_includes result, "SampleClass"
  end

  def test_format_output_handles_all_supported_formats
    formats = ["dot", "json", "html", "graph"]

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
    RailsDependencyExplorer::Analysis::AnalysisResult.new(dependencies)
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
