# frozen_string_literal: true

require "minitest/autorun"
require "stringio"
require_relative "../test_helper"
require_relative "../support/file_test_helpers"

class CommandTest < Minitest::Test
  include IOTestHelpers
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
    output, exit_code = run_cli_command([])

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
    output, exit_code = run_cli_command(["--help"])

    # Should display same help information
    assert_includes output, "Usage:"
    assert_includes output, "rails_dependency_explorer"
    assert_includes output, "analyze"
    assert_includes output, "Options:"

    assert_equal 0, exit_code
  end

  def test_cli_displays_version_with_version_flag
    output, exit_code = run_cli_command(["--version"])

    # Should display version information
    assert_includes output, RailsDependencyExplorer::VERSION

    assert_equal 0, exit_code
  end

  def test_cli_analyzes_single_file_with_default_output
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

    begin
      output, exit_code = run_cli_command(["analyze", temp_file.path])

      # Should analyze the file and output dependency information in default format (graph)
      assert_includes output, "UserService"
      assert_includes output, "UserRepository"
      assert_includes output, "EmailService"

      # Should exit successfully
      assert_equal 0, exit_code
    ensure
      temp_file.unlink
    end
  end



  def test_cli_supports_html_format
    assert_output_format("html") do |output|
      assert_includes output, "<html>"
      assert_includes output, "TestClass"
      assert_includes output, "Dependencies"
    end
  end

  def test_cli_supports_graph_format
    assert_output_format("graph") do |output|
      assert_includes output, "Dependencies found:"
      assert_includes output, "Classes:"
      assert_includes output, "TestClass"
    end
  end

  def test_cli_handles_invalid_format
    with_test_file do |test_file|
      output, exit_code = run_cli_command(["analyze", test_file, "--format", "invalid"])

      assert_includes output, "Error"
      assert_includes output, "invalid"
      assert_equal 1, exit_code
    end
  end

  def test_cli_outputs_html_format_to_file
    assert_file_output_format("html", "output.html") do |content|
      assert_includes content, "<html>"
      assert_includes content, "TestClass"
    end
  end

  def test_cli_outputs_graph_format_to_file
    assert_file_output_format("graph", "output.txt") do |content|
      assert_includes content, "Dependencies found:"
      assert_includes content, "TestClass"
    end
  end

  def test_cli_overwrites_existing_output_file
    with_test_file_and_output do |test_file, temp_dir|
      output_file = File.join(temp_dir, "output.dot")

      # Create existing file with content
      File.write(output_file, "existing content")

      _stdout_output, exit_code = run_cli_command_with_file_output(
        ["analyze", test_file, "--format", "dot", "--output", output_file]
      )

      assert_equal 0, exit_code
      new_content = File.read(output_file)
      assert_includes new_content, "digraph"
      refute_includes new_content, "existing content"
    end
  end

  def test_cli_handles_invalid_output_path
    with_test_file do |test_file|
      invalid_output_file = "/invalid/path/output.txt"

      output, exit_code = run_cli_command(["analyze", test_file, "--output", invalid_output_file])

      assert_includes output, "Error"
      assert_equal 1, exit_code
    end
  end

  def test_cli_supports_stats_analysis_option
    with_test_file do |test_file|
      output, exit_code = run_cli_command(["analyze", test_file, "--stats"])

      assert_includes output, "Statistics:"
      assert_includes output, "Total Classes:"
      assert_includes output, "Total Dependencies:"
      assert_equal 0, exit_code
    end
  end

  def test_cli_supports_circular_analysis_option
    assert_analysis_option("--circular") do |output|
      assert_includes output, "Circular Dependencies:"
    end
  end

  def test_cli_supports_depth_analysis_option
    assert_analysis_option("--depth") do |output|
      assert_includes output, "Dependency Depth:"
    end
  end

  def test_cli_handles_non_existent_file_error
    output, exit_code = run_cli_command(["analyze", "/non/existent/file.rb"])

    assert_includes output, "Error"
    assert_includes output, "not found"
    assert_equal 1, exit_code
  end

  def test_cli_handles_invalid_format_error
    with_test_file do |test_file|
      output, exit_code = run_cli_command(["analyze", test_file, "--format", "invalid"])

      assert_includes output, "Error"
      assert_includes output, "invalid"
      assert_includes output, "format"
      assert_equal 1, exit_code
    end
  end

  def test_cli_handles_non_existent_directory_error
    output, exit_code = run_cli_command(["analyze", "--directory", "/non/existent/directory"])

    assert_includes output, "Error"
    assert_includes output, "Directory not found"
    assert_equal 1, exit_code
  end

  def test_cli_handles_invalid_command_error
    output, exit_code = run_cli_command(["invalid_command"])

    assert_includes output, "Error"
    assert_includes output, "Unknown command"
    assert_equal 1, exit_code
  end

  private

  # Helper method to create a test file and output directory
  def with_test_file_and_output
    with_test_directory do |temp_dir|
      test_file = create_ruby_file(temp_dir, "test_class.rb", command_test_class_content)
      yield test_file, temp_dir
    end
  end

  # Helper method to run CLI command and capture output
  def run_cli_command(args)
    capture_output do
      cli = RailsDependencyExplorer::CLI::Command.new(args)
      cli.run
    end
  end

  # Helper method to run CLI command with file output and capture stdout
  def run_cli_command_with_file_output(args)
    run_cli_command(args)
  end

  # Helper method to capture stdout and stderr during command execution
  def capture_output
    exit_code = nil
    output = capture_io { exit_code = yield }
    [output[0], exit_code]
  end

  # Helper method to test output formats
  def assert_output_format(format)
    with_test_file do |test_file|
      output, exit_code = run_cli_command(["analyze", test_file, "--format", format])
      assert_equal 0, exit_code
      yield output
    end
  end

  # Helper method to test analysis options
  def assert_analysis_option(option)
    with_test_file do |test_file|
      output, exit_code = run_cli_command(["analyze", test_file, option])
      assert_equal 0, exit_code
      yield output
    end
  end

  # Helper method to test file output formats
  def assert_file_output_format(format, filename)
    with_test_file_and_output do |test_file, temp_dir|
      output_file = File.join(temp_dir, filename)
      stdout_output, exit_code = run_format_analysis(test_file, format, output_file)

      assert_successful_file_output(stdout_output, exit_code, output_file)
      yield File.read(output_file)
    end
  end

  # Helper method to create directory with test files
  def with_test_directory
    require "tmpdir"
    Dir.mktmpdir do |temp_dir|
      yield temp_dir
    end
  end

  # Helper method to create test files in a directory
  def create_directory_test_files(temp_dir)
    create_user_model_file(temp_dir)
    create_user_controller_file(temp_dir)
    create_non_ruby_file(temp_dir)
  end

  private

  def create_user_model_file(temp_dir)
    user_model = File.join(temp_dir, "user_model.rb")
    File.write(user_model, <<~RUBY)
      class UserModel
        def validate
          Logger.info("Validating user")
        end
      end
    RUBY
  end

  def create_user_controller_file(temp_dir)
    user_controller = File.join(temp_dir, "user_controller.rb")
    File.write(user_controller, <<~RUBY)
      class UserController
        def create
          UserModel.new
        end
      end
    RUBY
  end

  def create_non_ruby_file(temp_dir)
    readme_file = File.join(temp_dir, "README.md")
    File.write(readme_file, "# This is not Ruby code")
  end

  def run_format_analysis(test_file, format, output_file)
    run_cli_command_with_file_output(
      ["analyze", test_file, "--format", format, "--output", output_file]
    )
  end

  def assert_successful_file_output(stdout_output, exit_code, output_file)
    assert_equal "", stdout_output.strip
    assert_equal 0, exit_code
    assert File.exist?(output_file)
  end

  # Helper method to create nested directory structure for testing
  def with_nested_test_directory
    require "tmpdir"
    require "fileutils"

    Dir.mktmpdir do |temp_dir|
      models_dir = File.join(temp_dir, "models")
      concerns_dir = File.join(models_dir, "concerns")
      FileUtils.mkdir_p(concerns_dir)

      # Create Ruby file in root directory
      user_model = File.join(models_dir, "user.rb")
      File.write(user_model, <<~RUBY)
        class User
          def validate
            Validatable.check(self)
          end
        end
      RUBY

      # Create Ruby file in subdirectory
      validatable_concern = File.join(concerns_dir, "validatable.rb")
      File.write(validatable_concern, <<~RUBY)
        module Validatable
          def self.check(object)
            Logger.info("Checking object")
          end
        end
      RUBY

      yield models_dir
    end
  end
end
