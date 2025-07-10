# frozen_string_literal: true

require "minitest/autorun"
require "json"
require_relative "../test_helper"

class DependencyExplorerExportTest < Minitest::Test
  def setup
    @explorer = RailsDependencyExplorer::Analysis::DependencyExplorer.new
  end

  def test_dependency_explorer_exports_to_json
    ruby_code = create_user_service_code
    result = @explorer.analyze_code(ruby_code)
    json_output = result.to_json

    # Verify JSON integration with single parse
    parsed = JSON.parse(json_output)
    assert parsed.key?("dependencies")
    assert_includes parsed["dependencies"]["UserService"], "UserRepository"
  end

  def test_dependency_explorer_generates_html_report
    ruby_code = <<~RUBY
      class UserService
        def initialize
          @user_repo = UserRepository.new
          @email_service = EmailService.new
        end
      end
    RUBY

    result = @explorer.analyze_code(ruby_code)
    html_output = result.to_html

    # Should be valid HTML structure
    assert_includes html_output, "<html>"
    assert_includes html_output, "</html>"
    assert_includes html_output, "<head>"
    assert_includes html_output, "<body>"

    # Should include dependency information
    assert_includes html_output, "UserService"
    assert_includes html_output, "UserRepository"
    assert_includes html_output, "EmailService"

    # Should include statistics
    assert_includes html_output, "Dependencies Report"
    assert_includes html_output, "Total Classes"
    assert_includes html_output, "Total Dependencies"
  end

  private

  def create_user_service_code
    <<~RUBY
      class UserService
        def initialize
          @user_repo = UserRepository.new
          @logger = Logger.new
        end

        def create_user(data)
          user = User.new(data)
          @user_repo.save(user)
          @logger.info("User created")
        end
      end
    RUBY
  end
end
