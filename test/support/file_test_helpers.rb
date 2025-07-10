# frozen_string_literal: true

require "tempfile"
require "tmpdir"
require "fileutils"
require "stringio"

module FileTestHelpers
  # Creates a temporary Ruby file with the given content
  def with_test_file(content = default_test_class_content)
    Tempfile.create(["test", ".rb"]) do |file|
      file.write(content)
      file.flush
      yield file
    end
  end

  # Creates a temporary output file for testing file writing
  def with_output_file
    Tempfile.create("test_output") do |file|
      yield file
    end
  end

  # Creates a temporary directory with test files
  def with_test_directory
    Dir.mktmpdir do |temp_dir|
      yield temp_dir
    end
  end

  # Creates a Ruby file in the specified directory
  def create_ruby_file(directory, filename, content)
    file_path = File.join(directory, filename)
    File.write(file_path, content)
    file_path
  end

  # Creates nested directory structure for testing
  def create_nested_directory_structure(base_dir)
    models_dir = File.join(base_dir, "models")
    concerns_dir = File.join(models_dir, "concerns")
    services_dir = File.join(base_dir, "services")
    FileUtils.mkdir_p([models_dir, concerns_dir, services_dir])
    {models: models_dir, concerns: concerns_dir, services: services_dir}
  end

  def default_test_class_content
    <<~RUBY
      class TestClass
        def initialize
          @logger = Logger.new
        end
      end
    RUBY
  end

  def command_test_class_content
    <<~RUBY
      class TestClass
        def process
          Logger.info("Processing")
          DataProcessor.transform(data)
        end
      end
    RUBY
  end

  # Common test file content templates
  def user_model_content
    <<~RUBY
      class User
        def validate
          UserValidator.check(self)
        end
      end
    RUBY
  end

  def player_game_content
    <<~RUBY
      class Player
        def attack
          Enemy.health -= 10
        end
      end
    RUBY
  end

  def game_content
    <<~RUBY
      class Game
        def start
          Player.new
          Logger.info("Game started")
        end
      end
    RUBY
  end
end

# Module for capturing IO during tests
module IOTestHelpers
  # Captures stdout and stderr during block execution
  # Returns array [stdout_string, stderr_string]
  def capture_io
    original_stdout = $stdout
    original_stderr = $stderr
    $stdout = StringIO.new
    $stderr = StringIO.new

    yield

    [$stdout.string, $stderr.string]
  ensure
    $stdout = original_stdout
    $stderr = original_stderr
  end
end
