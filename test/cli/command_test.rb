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
end
