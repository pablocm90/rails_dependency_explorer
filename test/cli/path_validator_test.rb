# frozen_string_literal: true

require "test_helper"
require "tempfile"

class PathValidatorTest < Minitest::Test
  def setup
    @validator = RailsDependencyExplorer::CLI::PathValidator.new
  end

  def test_validate_file_path_returns_true_for_existing_file
    with_test_file do |file|
      assert @validator.validate_file_path(file.path)
    end
  end

  def test_validate_file_path_returns_false_for_nil_path
    output = capture_output do
      result = @validator.validate_file_path(nil)
      assert_equal false, result
    end
    assert_includes output[0], "Error: analyze command requires a file path"
  end

  def test_validate_file_path_returns_false_for_nonexistent_file
    output = capture_output do
      result = @validator.validate_file_path("nonexistent_file.rb")
      assert_equal false, result
    end
    assert_includes output[0], "Error: File not found: nonexistent_file.rb"
  end

  def test_validate_directory_path_returns_nil_for_existing_directory
    Dir.mktmpdir do |dir|
      result = @validator.validate_directory_path(dir)
      assert_nil result
    end
  end

  def test_validate_directory_path_returns_1_for_nil_path
    output = capture_output do
      result = @validator.validate_directory_path(nil)
      assert_equal 1, result
    end
    assert_includes output[0], "Error: --directory option requires a directory path"
  end

  def test_validate_directory_path_returns_1_for_nonexistent_directory
    output = capture_output do
      result = @validator.validate_directory_path("nonexistent_directory")
      assert_equal 1, result
    end
    assert_includes output[0], "Error: Directory not found: nonexistent_directory"
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

  def capture_output
    original_stdout = $stdout
    $stdout = StringIO.new
    yield
    [$stdout.string]
  ensure
    $stdout = original_stdout
  end
end
