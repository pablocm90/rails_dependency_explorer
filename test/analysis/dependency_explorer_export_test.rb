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

  def test_dependency_explorer_exports_to_csv
    ruby_code = create_user_service_code
    result = @explorer.analyze_code(ruby_code)
    csv_output = result.to_csv

    # Should be valid CSV format with header
    lines = csv_output.split("\n")
    assert_equal "Source,Target,Methods", lines.first

    # Should include dependency relationships
    assert_includes csv_output, "UserService,UserRepository"
    assert_includes csv_output, "UserService,Logger"
    assert_includes csv_output, "UserService,User"

    # Should have proper CSV structure (3 columns per row)
    lines[1..-1].each do |line|
      columns = line.split(",")
      assert_equal 3, columns.length, "Each CSV row should have 3 columns: #{line}"
    end
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
