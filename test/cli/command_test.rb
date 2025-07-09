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

  def test_cli_analyzes_directory_with_pattern_filtering
    require "tmpdir"
    require "fileutils"

    Dir.mktmpdir do |temp_dir|
      # Create Ruby files in the directory
      user_model = File.join(temp_dir, "user_model.rb")
      File.write(user_model, <<~RUBY)
        class UserModel
          def validate
            Logger.info("Validating user")
          end
        end
      RUBY

      user_controller = File.join(temp_dir, "user_controller.rb")
      File.write(user_controller, <<~RUBY)
        class UserController
          def create
            UserModel.new
          end
        end
      RUBY

      # Create a non-Ruby file that should be ignored
      readme_file = File.join(temp_dir, "README.md")
      File.write(readme_file, "# This is not Ruby code")

      # Test directory analysis with default pattern
      output, exit_code = run_cli_command(["analyze", "--directory", temp_dir])

      # Should analyze all Ruby files in directory
      assert_includes output, "UserModel"
      assert_includes output, "UserController"
      assert_includes output, "Logger"
      assert_includes output, "UserModel -> Logger"
      assert_includes output, "UserController -> UserModel"
      assert_equal 0, exit_code
    end
  end

  def test_cli_analyzes_directory_recursively
    require "tmpdir"
    require "fileutils"

    Dir.mktmpdir do |temp_dir|
      # Create nested directory structure
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

      # Test recursive directory analysis
      output, exit_code = run_cli_command(["analyze", "--directory", models_dir])

      # Should find classes in both root and subdirectories
      assert_includes output, "User"
      assert_includes output, "Validatable"
      assert_includes output, "Logger"
      assert_includes output, "User -> Validatable"
      assert_includes output, "Validatable -> Logger"
      assert_equal 0, exit_code
    end
  end

  def test_cli_supports_dot_format
    with_test_file do |test_file|
      output, exit_code = run_cli_command(["analyze", test_file, "--format", "dot"])

      assert_includes output, "digraph"
      assert_includes output, "TestClass"
      assert_includes output, "Logger"
      assert_includes output, "DataProcessor"
      assert_equal 0, exit_code
    end
  end

  def test_cli_supports_json_format
    require "json"

    with_test_file do |test_file|
      output, exit_code = run_cli_command(["analyze", test_file, "--format", "json"])

      # Should be valid JSON
      parsed_json = JSON.parse(output)
      assert parsed_json.key?("dependencies")
      assert parsed_json.key?("statistics")
      assert_equal 0, exit_code
    end
  end

  def test_cli_supports_html_format
    with_test_file do |test_file|
      output, exit_code = run_cli_command(["analyze", test_file, "--format", "html"])

      assert_includes output, "<html>"
      assert_includes output, "TestClass"
      assert_includes output, "Dependencies"
      assert_equal 0, exit_code
    end
  end

  def test_cli_supports_graph_format
    with_test_file do |test_file|
      output, exit_code = run_cli_command(["analyze", test_file, "--format", "graph"])

      assert_includes output, "Dependencies found:"
      assert_includes output, "Classes:"
      assert_includes output, "TestClass"
      assert_equal 0, exit_code
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

  def test_cli_outputs_dot_format_to_file
    with_test_file_and_output do |test_file, temp_dir|
      output_file = File.join(temp_dir, "output.dot")
      stdout_output, exit_code = run_cli_command_with_file_output(
        ["analyze", test_file, "--format", "dot", "--output", output_file]
      )

      # Should write to file, not stdout
      assert_equal "", stdout_output.strip
      assert_equal 0, exit_code
      assert File.exist?(output_file)

      file_content = File.read(output_file)
      assert_includes file_content, "digraph"
      assert_includes file_content, "TestClass"
      assert_includes file_content, "Logger"
    end
  end

  def test_cli_outputs_json_format_to_file
    require "json"

    with_test_file_and_output do |test_file, temp_dir|
      output_file = File.join(temp_dir, "output.json")
      stdout_output, exit_code = run_cli_command_with_file_output(
        ["analyze", test_file, "--format", "json", "--output", output_file]
      )

      # Should write to file, not stdout
      assert_equal "", stdout_output.strip
      assert_equal 0, exit_code
      assert File.exist?(output_file)

      file_content = File.read(output_file)
      parsed_json = JSON.parse(file_content)
      assert parsed_json.key?("dependencies")
      assert parsed_json.key?("statistics")
    end
  end

  def test_cli_outputs_html_format_to_file
    with_test_file_and_output do |test_file, temp_dir|
      output_file = File.join(temp_dir, "output.html")
      stdout_output, exit_code = run_cli_command_with_file_output(
        ["analyze", test_file, "--format", "html", "--output", output_file]
      )

      # Should write to file, not stdout
      assert_equal "", stdout_output.strip
      assert_equal 0, exit_code
      assert File.exist?(output_file)

      file_content = File.read(output_file)
      assert_includes file_content, "<html>"
      assert_includes file_content, "TestClass"
    end
  end

  def test_cli_outputs_graph_format_to_file
    with_test_file_and_output do |test_file, temp_dir|
      output_file = File.join(temp_dir, "output.txt")
      stdout_output, exit_code = run_cli_command_with_file_output(
        ["analyze", test_file, "--format", "graph", "--output", output_file]
      )

      # Should write to file, not stdout
      assert_equal "", stdout_output.strip
      assert_equal 0, exit_code
      assert File.exist?(output_file)

      file_content = File.read(output_file)
      assert_includes file_content, "Dependencies found:"
      assert_includes file_content, "TestClass"
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
    with_test_file do |test_file|
      output, exit_code = run_cli_command(["analyze", test_file, "--circular"])

      assert_includes output, "Circular Dependencies:"
      assert_equal 0, exit_code
    end
  end

  def test_cli_supports_depth_analysis_option
    with_test_file do |test_file|
      output, exit_code = run_cli_command(["analyze", test_file, "--depth"])

      assert_includes output, "Dependency Depth:"
      assert_equal 0, exit_code
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

  # Helper method to create a test file with dependencies
  def with_test_file
    with_test_file_and_output { |test_file, _temp_dir| yield test_file }
  end

  # Helper method to create a test file and output directory
  def with_test_file_and_output
    require "tmpdir"

    Dir.mktmpdir do |temp_dir|
      test_file = create_test_file(temp_dir)
      yield test_file, temp_dir
    end
  end

  # Helper method to create a test file with standard content
  def create_test_file(temp_dir)
    test_file = File.join(temp_dir, "test_class.rb")
    File.write(test_file, <<~RUBY)
      class TestClass
        def process
          Logger.info("Processing")
          DataProcessor.transform(data)
        end
      end
    RUBY
    test_file
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
    stdout = StringIO.new
    stderr = StringIO.new
    original_stdout = $stdout
    original_stderr = $stderr

    begin
      $stdout = stdout
      $stderr = stderr
      exit_code = yield
      [stdout.string, exit_code]
    ensure
      $stdout = original_stdout
      $stderr = original_stderr
    end
  end
end
