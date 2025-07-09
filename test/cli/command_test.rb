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

  def test_cli_analyzes_single_file_with_default_output
    # Create a temporary Ruby file for testing
    require "tempfile"

    temp_file = Tempfile.new(["test_class", ".rb"])
    temp_file.write(<<~RUBY)
      class UserService
        def initialize
          @user_repo = UserRepository.new
          @email_service = EmailService.new
        end
      end
    RUBY
    temp_file.close

    $stdout = @stdout
    $stderr = @stderr

    cli = RailsDependencyExplorer::CLI::Command.new(["analyze", temp_file.path])
    exit_code = cli.run

    output = @stdout.string

    # Should analyze the file and output dependency information in default format (graph)
    assert_includes output, "UserService"
    assert_includes output, "UserRepository"
    assert_includes output, "EmailService"

    # Should exit successfully
    assert_equal 0, exit_code

    temp_file.unlink
  end
end
