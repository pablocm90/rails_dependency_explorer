# frozen_string_literal: true

require "minitest/autorun"
require "stringio"
require_relative "../test_helper"

class CommandTest < Minitest::Test
  def setup
    @original_stdout = $stdout
    @original_stderr = $stderr
    @stdout = StringIO.new
    @stderr = StringIO.new
  end

  def teardown
    $stdout = @original_stdout
    $stderr = @original_stderr
  end

  def test_cli_displays_help_when_no_arguments_provided
    # Capture output
    $stdout = @stdout
    $stderr = @stderr

    # This should trigger help display when no arguments are provided
    cli = RailsDependencyExplorer::CLI::Command.new([])
    exit_code = cli.run

    output = @stdout.string

    # Should display help information
    assert_includes output, "Usage:"
    assert_includes output, "rails_dependency_explorer"
    assert_includes output, "analyze"
    assert_includes output, "Options:"
    assert_includes output, "--help"
    assert_includes output, "--version"
    
    # Should exit with success code for help display
    assert_equal 0, exit_code
  end

  def test_cli_displays_help_with_help_flag
    $stdout = @stdout
    $stderr = @stderr

    cli = RailsDependencyExplorer::CLI::Command.new(["--help"])
    exit_code = cli.run

    output = @stdout.string

    # Should display same help information
    assert_includes output, "Usage:"
    assert_includes output, "rails_dependency_explorer"
    assert_includes output, "analyze"
    assert_includes output, "Options:"
    
    assert_equal 0, exit_code
  end

  def test_cli_displays_version_with_version_flag
    $stdout = @stdout
    $stderr = @stderr

    cli = RailsDependencyExplorer::CLI::Command.new(["--version"])
    exit_code = cli.run

    output = @stdout.string

    # Should display version information
    assert_includes output, RailsDependencyExplorer::VERSION
    
    assert_equal 0, exit_code
  end
end
