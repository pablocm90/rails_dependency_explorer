# frozen_string_literal: true

require "test_helper"
require "tempfile"

class AnalysisExecutorTest < Minitest::Test
  def setup
    @output_writer = RailsDependencyExplorer::CLI::OutputWriter.new
    @executor = RailsDependencyExplorer::CLI::AnalysisExecutor.new(@output_writer)
  end

  def test_perform_file_analysis_returns_0_on_success
    with_test_file do |file|
      result = @executor.perform_file_analysis(file.path, "json", nil, {})
      assert_equal 0, result
    end
  end

  def test_perform_file_analysis_returns_1_on_error
    result = @executor.perform_file_analysis("nonexistent.rb", "json", nil, {})
    assert_equal 1, result
  end

  def test_perform_directory_analysis_returns_0_on_success
    Dir.mktmpdir do |dir|
      create_test_file_in_directory(dir, "test.rb", "class TestClass; end")
      result = @executor.perform_directory_analysis(dir, "json", nil, {})
      assert_equal 0, result
    end
  end

  def test_perform_directory_analysis_returns_0_for_nonexistent_directory
    # Directory analysis doesn't fail for nonexistent directories,
    # it just returns empty results (Dir.glob returns empty array)
    result = @executor.perform_directory_analysis("nonexistent_dir", "json", nil, {})
    assert_equal 0, result
  end

  def test_analyze_single_file_returns_analysis_result
    with_test_file do |file|
      result = @executor.analyze_single_file(file.path)
      assert_instance_of RailsDependencyExplorer::Analysis::AnalysisResult, result
    end
  end

  def test_analyze_directory_files_returns_analysis_result
    Dir.mktmpdir do |dir|
      create_test_file_in_directory(dir, "test.rb", "class TestClass; end")
      result = @executor.analyze_directory_files(dir)
      assert_instance_of RailsDependencyExplorer::Analysis::AnalysisResult, result
    end
  end

  private

  def with_test_file
    file = Tempfile.new(["test", ".rb"])
    file.write("class TestClass; end")
    file.close
    yield file
  ensure
    file&.unlink
  end

  def create_test_file_in_directory(dir, filename, content)
    file_path = File.join(dir, filename)
    File.write(file_path, content)
  end
end
