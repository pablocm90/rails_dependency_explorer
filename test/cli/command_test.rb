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

  def test_cli_supports_multiple_output_formats
    require "tmpdir"
    require "json"

    Dir.mktmpdir do |temp_dir|
      # Create a test Ruby file with dependencies
      test_file = File.join(temp_dir, "test_class.rb")
      File.write(test_file, <<~RUBY)
        class TestClass
          def process
            Logger.info("Processing")
            DataProcessor.transform(data)
          end
        end
      RUBY

      # Test DOT format
      @stdout = StringIO.new
      @stderr = StringIO.new
      $stdout = @stdout
      $stderr = @stderr

      cli = RailsDependencyExplorer::CLI::Command.new(["analyze", test_file, "--format", "dot"])
      exit_code = cli.run
      dot_output = @stdout.string

      assert_includes dot_output, "digraph"
      assert_includes dot_output, "TestClass"
      assert_includes dot_output, "Logger"
      assert_includes dot_output, "DataProcessor"
      assert_equal 0, exit_code

      # Test JSON format
      @stdout = StringIO.new
      @stderr = StringIO.new
      $stdout = @stdout
      $stderr = @stderr

      cli = RailsDependencyExplorer::CLI::Command.new(["analyze", test_file, "--format", "json"])
      exit_code = cli.run
      json_output = @stdout.string

      # Should be valid JSON
      parsed_json = JSON.parse(json_output)
      assert parsed_json.key?("dependencies")
      assert parsed_json.key?("statistics")
      assert_equal 0, exit_code

      # Test HTML format
      @stdout = StringIO.new
      @stderr = StringIO.new
      $stdout = @stdout
      $stderr = @stderr

      cli = RailsDependencyExplorer::CLI::Command.new(["analyze", test_file, "--format", "html"])
      exit_code = cli.run
      html_output = @stdout.string

      assert_includes html_output, "<html>"
      assert_includes html_output, "TestClass"
      assert_includes html_output, "Dependencies"
      assert_equal 0, exit_code

      # Test graph format (default)
      @stdout = StringIO.new
      @stderr = StringIO.new
      $stdout = @stdout
      $stderr = @stderr

      cli = RailsDependencyExplorer::CLI::Command.new(["analyze", test_file, "--format", "graph"])
      exit_code = cli.run
      graph_output = @stdout.string

      assert_includes graph_output, "Dependencies found:"
      assert_includes graph_output, "Classes:"
      assert_includes graph_output, "TestClass"
      assert_equal 0, exit_code

      # Test invalid format
      @stdout = StringIO.new
      @stderr = StringIO.new
      $stdout = @stdout
      $stderr = @stderr

      cli = RailsDependencyExplorer::CLI::Command.new(["analyze", test_file, "--format", "invalid"])
      exit_code = cli.run
      error_output = @stdout.string

      assert_includes error_output, "Error"
      assert_includes error_output, "invalid"
      assert_equal 1, exit_code
    end
  end

  def test_cli_supports_output_to_file
    require "tmpdir"
    require "json"

    Dir.mktmpdir do |temp_dir|
      # Create a test Ruby file with dependencies
      test_file = File.join(temp_dir, "test_class.rb")
      File.write(test_file, <<~RUBY)
        class TestClass
          def process
            Logger.info("Processing")
            DataProcessor.transform(data)
          end
        end
      RUBY

      # Test DOT format output to file
      dot_output_file = File.join(temp_dir, "output.dot")

      @stdout = StringIO.new
      @stderr = StringIO.new
      $stdout = @stdout
      $stderr = @stderr

      cli = RailsDependencyExplorer::CLI::Command.new(["analyze", test_file, "--format", "dot", "--output", dot_output_file])
      exit_code = cli.run
      stdout_content = @stdout.string

      # Should write to file, not stdout
      assert_equal "", stdout_content.strip
      assert_equal 0, exit_code
      assert File.exist?(dot_output_file)

      dot_content = File.read(dot_output_file)
      assert_includes dot_content, "digraph"
      assert_includes dot_content, "TestClass"
      assert_includes dot_content, "Logger"

      # Test JSON format output to file
      json_output_file = File.join(temp_dir, "output.json")

      @stdout = StringIO.new
      @stderr = StringIO.new
      $stdout = @stdout
      $stderr = @stderr

      cli = RailsDependencyExplorer::CLI::Command.new(["analyze", test_file, "--format", "json", "--output", json_output_file])
      exit_code = cli.run
      stdout_content = @stdout.string

      # Should write to file, not stdout
      assert_equal "", stdout_content.strip
      assert_equal 0, exit_code
      assert File.exist?(json_output_file)

      json_content = File.read(json_output_file)
      parsed_json = JSON.parse(json_content)
      assert parsed_json.key?("dependencies")
      assert parsed_json.key?("statistics")

      # Test HTML format output to file
      html_output_file = File.join(temp_dir, "output.html")

      @stdout = StringIO.new
      @stderr = StringIO.new
      $stdout = @stdout
      $stderr = @stderr

      cli = RailsDependencyExplorer::CLI::Command.new(["analyze", test_file, "--format", "html", "--output", html_output_file])
      exit_code = cli.run
      stdout_content = @stdout.string

      # Should write to file, not stdout
      assert_equal "", stdout_content.strip
      assert_equal 0, exit_code
      assert File.exist?(html_output_file)

      html_content = File.read(html_output_file)
      assert_includes html_content, "<html>"
      assert_includes html_content, "TestClass"

      # Test graph format output to file
      graph_output_file = File.join(temp_dir, "output.txt")

      @stdout = StringIO.new
      @stderr = StringIO.new
      $stdout = @stdout
      $stderr = @stderr

      cli = RailsDependencyExplorer::CLI::Command.new(["analyze", test_file, "--format", "graph", "--output", graph_output_file])
      exit_code = cli.run
      stdout_content = @stdout.string

      # Should write to file, not stdout
      assert_equal "", stdout_content.strip
      assert_equal 0, exit_code
      assert File.exist?(graph_output_file)

      graph_content = File.read(graph_output_file)
      assert_includes graph_content, "Dependencies found:"
      assert_includes graph_content, "TestClass"

      # Test file overwrite behavior
      File.write(dot_output_file, "existing content")

      @stdout = StringIO.new
      @stderr = StringIO.new
      $stdout = @stdout
      $stderr = @stderr

      cli = RailsDependencyExplorer::CLI::Command.new(["analyze", test_file, "--format", "dot", "--output", dot_output_file])
      exit_code = cli.run

      assert_equal 0, exit_code
      new_content = File.read(dot_output_file)
      assert_includes new_content, "digraph"
      refute_includes new_content, "existing content"

      # Test invalid output path
      invalid_output_file = "/invalid/path/output.txt"

      @stdout = StringIO.new
      @stderr = StringIO.new
      $stdout = @stdout
      $stderr = @stderr

      cli = RailsDependencyExplorer::CLI::Command.new(["analyze", test_file, "--output", invalid_output_file])
      exit_code = cli.run
      error_output = @stdout.string

      assert_includes error_output, "Error"
      assert_equal 1, exit_code
    end
  end
end
