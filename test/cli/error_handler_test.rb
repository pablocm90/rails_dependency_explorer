# frozen_string_literal: true

require "minitest/autorun"
require_relative "../test_helper"
require_relative "../support/file_test_helpers"
require_relative "../../lib/rails_dependency_explorer/cli/error_handler"

class ErrorHandlerTest < Minitest::Test
  include IOTestHelpers

  def test_handle_analysis_error_returns_exit_code_1
    error = StandardError.new("test error")
    
    output = capture_io do
      result = RailsDependencyExplorer::CLI::ErrorHandler.handle_analysis_error("file", error)
      assert_equal 1, result
    end
    
    assert_includes output[0], "Error analyzing file: test error"
  end

  def test_handle_analysis_error_formats_directory_message
    error = StandardError.new("directory error")
    
    output = capture_io do
      result = RailsDependencyExplorer::CLI::ErrorHandler.handle_analysis_error("directory", error)
      assert_equal 1, result
    end
    
    assert_includes output[0], "Error analyzing directory: directory error"
  end

  def test_handle_validation_error_returns_false
    output = capture_io do
      result = RailsDependencyExplorer::CLI::ErrorHandler.handle_validation_error("test message")
      assert_equal false, result
    end
    
    assert_includes output[0], "Error: test message"
  end

  def test_handle_missing_path_error_for_file
    output = capture_io do
      result = RailsDependencyExplorer::CLI::ErrorHandler.handle_missing_path_error(:file)
      assert_equal false, result
    end
    
    assert_includes output[0], "Error: analyze command requires a file path"
    assert_includes output[0], "Usage: rails_dependency_explorer analyze <path>"
  end

  def test_handle_missing_path_error_for_directory
    output = capture_io do
      result = RailsDependencyExplorer::CLI::ErrorHandler.handle_missing_path_error(:directory)
      assert_equal false, result
    end
    
    assert_includes output[0], "Error: --directory option requires a directory path"
  end

  def test_handle_not_found_error_for_file
    output = capture_io do
      result = RailsDependencyExplorer::CLI::ErrorHandler.handle_not_found_error(:file, "/test/path")
      assert_equal false, result
    end
    
    assert_includes output[0], "Error: File not found: /test/path"
  end

  def test_handle_not_found_error_for_directory
    output = capture_io do
      result = RailsDependencyExplorer::CLI::ErrorHandler.handle_not_found_error(:directory, "/test/dir")
      assert_equal false, result
    end
    
    assert_includes output[0], "Error: Directory not found: /test/dir"
  end
end
