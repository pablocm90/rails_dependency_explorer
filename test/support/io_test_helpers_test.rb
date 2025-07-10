# frozen_string_literal: true

require "test_helper"
require_relative "file_test_helpers"

class IOTestHelpersTest < Minitest::Test
  include IOTestHelpers

  def test_capture_io_captures_stdout_and_stderr
    stdout_output, stderr_output = capture_io do
      puts "Hello stdout"
      warn "Hello stderr"
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
    rescue
      # Expected exception
    end

    assert_same original_stdout, $stdout
    assert_same original_stderr, $stderr
  end

  # Test to verify shared test helpers are working correctly after refactoring
  def test_shared_test_helpers_eliminate_duplication
    # Verify that shared modules are available in test classes
    test_instance = self

    # Pattern 1: DependencyExplorerTestHelpers methods are available
    assert_respond_to test_instance, :setup_dependency_explorer
    assert_respond_to test_instance, :player_code
    assert_respond_to test_instance, :game_code
    assert_respond_to test_instance, :simple_dependency_data
    assert_respond_to test_instance, :complex_dependency_data

    # Pattern 2: AnalysisResultTestHelpers methods are available
    assert_respond_to test_instance, :create_simple_analysis_result
    assert_respond_to test_instance, :create_complex_analysis_result
    assert_respond_to test_instance, :assert_simple_graph_structure

    # Pattern 3: FileTestHelpers methods are still available
    assert_respond_to test_instance, :with_test_file
    assert_respond_to test_instance, :create_ruby_file

    # Verify the shared helpers actually work
    setup_dependency_explorer
    refute_nil @explorer
    assert_instance_of RailsDependencyExplorer::Analysis::DependencyExplorer, @explorer

    # Verify shared code templates work
    assert_includes player_code, "class Player"
    assert_includes game_code, "class Game"

    # Verify shared analysis result creation works
    result = create_simple_analysis_result
    assert_instance_of RailsDependencyExplorer::Analysis::AnalysisResult, result
  end
end
