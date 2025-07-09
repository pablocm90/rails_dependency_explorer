# frozen_string_literal: true

require "minitest/autorun"
require_relative "../../lib/rails_dependency_explorer/cli/help_display"

class HelpDisplayTest < Minitest::Test
  def setup
    @help_display = RailsDependencyExplorer::CLI::HelpDisplay.new
  end

  def test_display_help_shows_usage_information
    output = capture_io do
      @help_display.display_help
    end

    help_text = output[0]

    # Check for main usage line
    assert_includes help_text, "Usage: rails_dependency_explorer analyze <path> [options]"

    # Check for commands section
    assert_includes help_text, "Commands:"
    assert_includes help_text, "analyze <path>"

    # Check for options section
    assert_includes help_text, "Options:"
    assert_includes help_text, "--format, -f FORMAT"
    assert_includes help_text, "--output, -o FILE"
    assert_includes help_text, "--directory, -d"
    assert_includes help_text, "--help, -h"
    assert_includes help_text, "--version"

    # Check for examples section
    assert_includes help_text, "Examples:"
    assert_includes help_text, "rails_dependency_explorer analyze app/models/user.rb"
    assert_includes help_text, "rails_dependency_explorer analyze app/ --format html --output report.html"
  end

  def test_display_help_includes_all_format_options
    output = capture_io do
      @help_display.display_help
    end

    help_text = output[0]

    # Check that all supported formats are mentioned
    assert_includes help_text, "dot, json, html, graph"
  end

  def test_display_help_includes_future_options
    output = capture_io do
      @help_display.display_help
    end

    help_text = output[0]

    # Check for future CLI options that are planned
    assert_includes help_text, "--stats, -s"
    assert_includes help_text, "--circular, -c"
    assert_includes help_text, "--depth"
    assert_includes help_text, "--verbose, -v"
    assert_includes help_text, "--quiet, -q"
    assert_includes help_text, "--config CONFIG_FILE"
  end

  def test_display_version_shows_version_number
    output = capture_io do
      @help_display.display_version
    end

    version_text = output[0].strip

    # Should show the version number
    assert_match(/\d+\.\d+\.\d+/, version_text)

    # Should be the actual version from the VERSION constant
    assert_equal RailsDependencyExplorer::VERSION, version_text
  end

  def test_display_help_shows_comprehensive_examples
    output = capture_io do
      @help_display.display_help
    end

    help_text = output[0]

    # Check for various example patterns
    assert_includes help_text, "app/models/user.rb"
    assert_includes help_text, "--format html --output report.html"
    assert_includes help_text, "--pattern \"*_service.rb\" --stats --circular"
    assert_includes help_text, "--format dot --output dependencies.dot --verbose"
  end

  def test_display_help_output_is_well_formatted
    output = capture_io do
      @help_display.display_help
    end

    help_text = output[0]

    # Should have proper sections
    sections = ["Usage:", "Commands:", "Options:", "Examples:"]
    sections.each do |section|
      assert_includes help_text, section
    end

    # Should have proper indentation (at least some spaces for options)
    lines = help_text.split("\n")
    option_lines = lines.select { |line| line.include?("--") && !line.include?("Usage:") && !line.include?("Examples:") }

    refute_empty option_lines
    option_lines.each do |line|
      assert line.start_with?("  "), "Option line should be indented: #{line}"
    end
  end

  private

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
