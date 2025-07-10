# frozen_string_literal: true

require "minitest/autorun"
require_relative "../support/file_test_helpers"
require_relative "../../lib/rails_dependency_explorer/cli/help_display"

class HelpDisplayTest < Minitest::Test
  include IOTestHelpers
  def setup
    @help_display = RailsDependencyExplorer::CLI::HelpDisplay.new
  end

  def test_display_help_shows_usage_information
    assert_help_includes([
      "Usage: rails_dependency_explorer analyze <path> [options]",
      "Commands:",
      "analyze <path>",
      "Options:",
      "--format, -f FORMAT",
      "--output, -o FILE",
      "--directory, -d",
      "--help, -h",
      "--version",
      "Examples:",
      "rails_dependency_explorer analyze app/models/user.rb",
      "rails_dependency_explorer analyze app/ --format html --output report.html"
    ])
  end

  def test_display_help_includes_all_format_options
    assert_help_includes("dot, json, html, graph")
  end

  def test_display_help_includes_future_options
    assert_help_includes([
      "--stats, -s",
      "--circular, -c",
      "--depth",
      "--config CONFIG_FILE"
    ])
  end

  def test_display_version_shows_version_number
    version_text = capture_version_output.strip

    # Should show the version number
    assert_match(/\d+\.\d+\.\d+/, version_text)

    # Should be the actual version from the VERSION constant
    assert_equal RailsDependencyExplorer::VERSION, version_text
  end

  def test_display_help_shows_comprehensive_examples
    assert_help_includes([
      "app/models/user.rb",
      "--format html --output report.html",
      "--pattern \"*_service.rb\" --stats --circular",
      "--format dot --output dependencies.dot"
    ])
  end

  def test_display_help_output_is_well_formatted
    help_text = capture_help_output

    # Should have proper sections
    assert_help_includes(["Usage:", "Commands:", "Options:", "Examples:"])

    # Should have proper indentation (at least some spaces for options)
    assert_proper_option_indentation(help_text)
  end

  private

  def capture_help_output
    output = capture_io do
      @help_display.display_help
    end
    output[0]
  end

  def capture_version_output
    output = capture_io do
      @help_display.display_version
    end
    output[0]
  end

  def assert_help_includes(expected_content)
    help_text = capture_help_output
    if expected_content.is_a?(Array)
      expected_content.each { |content| assert_includes help_text, content }
    else
      assert_includes help_text, expected_content
    end
  end

  def assert_proper_option_indentation(help_text)
    lines = help_text.split("\n")
    option_lines = lines.select { |line| line.include?("--") && !line.include?("Usage:") && !line.include?("Examples:") }

    refute_empty option_lines
    option_lines.each do |line|
      assert line.start_with?("  "), "Option line should be indented: #{line}"
    end
  end
end
