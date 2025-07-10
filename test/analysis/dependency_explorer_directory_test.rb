# frozen_string_literal: true

require "minitest/autorun"
require "json"
require_relative "../test_helper"

class DependencyExplorerDirectoryTest < Minitest::Test
  def setup
    @explorer = RailsDependencyExplorer::Analysis::DependencyExplorer.new
  end

  def test_analyze_directory_finds_files_in_nested_subdirectories
    require "tmpdir"
    require "fileutils"

    Dir.mktmpdir do |temp_dir|
      dirs = create_nested_directory_structure(temp_dir)
      create_user_file(dirs[:models])
      create_user_validator_file(dirs[:concerns])
      create_email_service_file(dirs[:services])

      result = @explorer.analyze_directory(temp_dir)
      graph = result.to_graph

      expected_nodes = ["User", "UserValidator", "EmailService"]
      expected_nodes.each { |node| assert_includes graph[:nodes], node }
    end
  end

  def test_analyze_directory_detects_cross_directory_dependencies
    require "tmpdir"
    require "fileutils"

    Dir.mktmpdir do |temp_dir|
      dirs = create_nested_directory_structure(temp_dir)
      create_user_file(dirs[:models])
      create_user_validator_file(dirs[:concerns])

      result = @explorer.analyze_directory(temp_dir)
      graph = result.to_graph

      assert_includes graph[:edges], ["User", "UserValidator"]
    end
  end

  def test_analyze_directory_processes_all_dependency_types_recursively
    require "tmpdir"
    require "fileutils"

    Dir.mktmpdir do |temp_dir|
      dirs = create_nested_directory_structure(temp_dir)
      create_user_validator_file(dirs[:concerns])
      create_email_service_file(dirs[:services])

      result = @explorer.analyze_directory(temp_dir)
      graph = result.to_graph

      expected_edges = [["UserValidator", "Logger"], ["EmailService", "Mailer"]]
      expected_edges.each { |edge| assert_includes graph[:edges], edge }
    end
  end

  private

  def create_nested_directory_structure(temp_dir)
    models_dir = File.join(temp_dir, "models")
    concerns_dir = File.join(models_dir, "concerns")
    services_dir = File.join(temp_dir, "services")
    FileUtils.mkdir_p([models_dir, concerns_dir, services_dir])
    {models: models_dir, concerns: concerns_dir, services: services_dir}
  end

  def create_user_file(models_dir)
    File.write(File.join(models_dir, "user.rb"), <<~RUBY)
      class User
        def validate
          UserValidator.check(self)
        end
      end
    RUBY
  end

  def create_user_validator_file(concerns_dir)
    File.write(File.join(concerns_dir, "user_validator.rb"), <<~RUBY)
      module UserValidator
        def self.check(user)
          Logger.info("Validating user")
        end
      end
    RUBY
  end

  def create_email_service_file(services_dir)
    File.write(File.join(services_dir, "email_service.rb"), <<~RUBY)
      class EmailService
        def send_notification
          Mailer.deliver_now
        end
      end
    RUBY
  end
end
