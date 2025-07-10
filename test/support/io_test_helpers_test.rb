# frozen_string_literal: true

require "test_helper"
require_relative "file_test_helpers"

class IOTestHelpersTest < Minitest::Test
  include IOTestHelpers

  def test_capture_io_captures_stdout_and_stderr
    stdout_output, stderr_output = capture_io do
      puts "Hello stdout"
      $stderr.puts "Hello stderr"
    end

    assert_equal "Hello stdout\n", stdout_output
    assert_equal "Hello stderr\n", stderr_output
  end

  def test_capture_io_restores_original_streams
    original_stdout = $stdout
    original_stderr = $stderr

    capture_io do
      puts "test output"
    end

    assert_same original_stdout, $stdout
    assert_same original_stderr, $stderr
  end

  def test_capture_io_restores_streams_on_exception
    original_stdout = $stdout
    original_stderr = $stderr

    begin
      capture_io do
        raise StandardError, "test error"
      end
    rescue StandardError
      # Expected exception
    end

    assert_same original_stdout, $stdout
    assert_same original_stderr, $stderr
  end
end
