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

      # Capture output
      @stdout = StringIO.new
      @stderr = StringIO.new
      $stdout = @stdout
      $stderr = @stderr

      # Test directory analysis with default pattern
      cli = RailsDependencyExplorer::CLI::Command.new(["analyze", "--directory", temp_dir])
      exit_code = cli.run

      output = @stdout.string

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

      # Capture output
      @stdout = StringIO.new
      @stderr = StringIO.new
      $stdout = @stdout
      $stderr = @stderr

      # Test recursive directory analysis
      cli = RailsDependencyExplorer::CLI::Command.new(["analyze", "--directory", models_dir])
      exit_code = cli.run

      output = @stdout.string

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

  def test_cli_supports_analysis_options
    require "tmpdir"

    Dir.mktmpdir do |temp_dir|
      # Create a test Ruby file with dependencies
      test_file = File.join(temp_dir, "test_class.rb")
      File.write(test_file, <<~RUBY)
        class TestClass
          def initialize
            @logger = Logger.new
          end
        end
      RUBY

      # Test --stats flag
      @stdout = StringIO.new
      @stderr = StringIO.new
      $stdout = @stdout
      $stderr = @stderr

      cli = RailsDependencyExplorer::CLI::Command.new(["analyze", test_file, "--stats"])
      exit_code = cli.run
      stats_output = @stdout.string

      assert_includes stats_output, "Statistics:"
      assert_includes stats_output, "Total Classes:"
      assert_includes stats_output, "Total Dependencies:"
      assert_equal 0, exit_code

      # Test --circular flag
      @stdout = StringIO.new
      @stderr = StringIO.new
      $stdout = @stdout
      $stderr = @stderr

      cli = RailsDependencyExplorer::CLI::Command.new(["analyze", test_file, "--circular"])
      exit_code = cli.run
      circular_output = @stdout.string

      assert_includes circular_output, "Circular Dependencies:"
      assert_equal 0, exit_code

      # Test --depth flag
      @stdout = StringIO.new
      @stderr = StringIO.new
      $stdout = @stdout
      $stderr = @stderr

      cli = RailsDependencyExplorer::CLI::Command.new(["analyze", test_file, "--depth"])
      exit_code = cli.run
      depth_output = @stdout.string

      assert_includes depth_output, "Dependency Depth:"
      assert_equal 0, exit_code
    end
  end

  def test_cli_handles_invalid_inputs_gracefully
    require "tmpdir"

    Dir.mktmpdir do |temp_dir|
      # Test non-existent file
      @stdout = StringIO.new
      @stderr = StringIO.new
      $stdout = @stdout
      $stderr = @stderr

      cli = RailsDependencyExplorer::CLI::Command.new(["analyze", "/non/existent/file.rb"])
      exit_code = cli.run
      error_output = @stdout.string

      assert_includes error_output, "Error"
      assert_includes error_output, "not found"
      assert_equal 1, exit_code

      # Test invalid output format
      test_file = File.join(temp_dir, "test.rb")
      File.write(test_file, "class Test; end")

      @stdout = StringIO.new
      @stderr = StringIO.new
      $stdout = @stdout
      $stderr = @stderr

      cli = RailsDependencyExplorer::CLI::Command.new(["analyze", test_file, "--format", "invalid"])
      exit_code = cli.run
      error_output = @stdout.string

      assert_includes error_output, "Error"
      assert_includes error_output, "invalid"
      assert_includes error_output, "format"
      assert_equal 1, exit_code

      # Test non-existent directory
      @stdout = StringIO.new
      @stderr = StringIO.new
      $stdout = @stdout
      $stderr = @stderr

      cli = RailsDependencyExplorer::CLI::Command.new(["analyze", "--directory", "/non/existent/directory"])
      exit_code = cli.run
      error_output = @stdout.string

      assert_includes error_output, "Error"
      assert_includes error_output, "Directory not found"
      assert_equal 1, exit_code

      # Test invalid command
      @stdout = StringIO.new
      @stderr = StringIO.new
      $stdout = @stdout
      $stderr = @stderr

      cli = RailsDependencyExplorer::CLI::Command.new(["invalid_command"])
      exit_code = cli.run
      error_output = @stdout.string

      assert_includes error_output, "Error"
      assert_includes error_output, "Unknown command"
      assert_equal 1, exit_code
    end
  end

  private

  # Helper method to create a test file with dependencies
  def with_test_file
    require "tmpdir"

    Dir.mktmpdir do |temp_dir|
      test_file = File.join(temp_dir, "test_class.rb")
      File.write(test_file, <<~RUBY)
        class TestClass
          def process
            Logger.info("Processing")
            DataProcessor.transform(data)
          end
        end
      RUBY

      yield test_file
    end
  end

  # Helper method to create a test file and output directory
  def with_test_file_and_output
    require "tmpdir"

    Dir.mktmpdir do |temp_dir|
      test_file = File.join(temp_dir, "test_class.rb")
      File.write(test_file, <<~RUBY)
        class TestClass
          def process
            Logger.info("Processing")
            DataProcessor.transform(data)
          end
        end
      RUBY

      yield test_file, temp_dir
    end
  end

  # Helper method to run CLI command and capture output
  def run_cli_command(args)
    stdout = StringIO.new
    stderr = StringIO.new
    original_stdout = $stdout
    original_stderr = $stderr

    begin
      $stdout = stdout
      $stderr = stderr

      cli = RailsDependencyExplorer::CLI::Command.new(args)
      exit_code = cli.run

      [stdout.string, exit_code]
    ensure
      $stdout = original_stdout
      $stderr = original_stderr
    end
  end

  # Helper method to run CLI command with file output and capture stdout
  def run_cli_command_with_file_output(args)
    stdout = StringIO.new
    stderr = StringIO.new
    original_stdout = $stdout
    original_stderr = $stderr

    begin
      $stdout = stdout
      $stderr = stderr

      cli = RailsDependencyExplorer::CLI::Command.new(args)
      exit_code = cli.run

      [stdout.string, exit_code]
    ensure
      $stdout = original_stdout
      $stderr = original_stderr
    end
  end
end
