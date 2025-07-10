# frozen_string_literal: true

require "test_helper"

class OptionExtractorTest < Minitest::Test
  def test_extract_format_option_returns_value_when_present
    extractor = create_extractor(["analyze", "file.rb", "--format", "json"])
    assert_equal "json", extractor.extract_format_option
  end

  def test_extract_format_option_returns_nil_when_absent
    extractor = create_extractor(["analyze", "file.rb"])
    assert_nil extractor.extract_format_option
  end

  def test_extract_format_option_returns_missing_when_value_missing
    extractor = create_extractor(["analyze", "file.rb", "--format"])
    assert_equal :missing, extractor.extract_format_option
  end

  def test_extract_output_option_returns_value_when_present
    extractor = create_extractor(["analyze", "file.rb", "--output", "result.json"])
    assert_equal "result.json", extractor.extract_output_option
  end

  def test_extract_output_option_returns_nil_when_absent
    extractor = create_extractor(["analyze", "file.rb"])
    assert_nil extractor.extract_output_option
  end

  def test_extract_output_option_returns_missing_when_value_missing
    extractor = create_extractor(["analyze", "file.rb", "--output"])
    assert_equal :missing, extractor.extract_output_option
  end

  def test_extract_directory_option_returns_value_when_present
    extractor = create_extractor(["analyze", "--directory", "app/models"])
    assert_equal "app/models", extractor.extract_directory_option
  end

  def test_extract_directory_option_returns_nil_when_absent
    extractor = create_extractor(["analyze", "file.rb"])
    assert_nil extractor.extract_directory_option
  end

  def test_extract_directory_option_returns_missing_when_value_missing
    extractor = create_extractor(["analyze", "--directory"])
    assert_equal :missing, extractor.extract_directory_option
  end

  def test_get_command_returns_first_argument
    extractor = create_extractor(["analyze", "file.rb"])
    assert_equal "analyze", extractor.get_command
  end

  def test_get_command_returns_nil_for_empty_args
    extractor = create_extractor([])
    assert_nil extractor.get_command
  end

  def test_get_file_path_returns_second_argument
    extractor = create_extractor(["analyze", "app/models/user.rb"])
    assert_equal "app/models/user.rb", extractor.get_file_path
  end

  def test_get_file_path_returns_nil_when_missing
    extractor = create_extractor(["analyze"])
    assert_nil extractor.get_file_path
  end

  def test_has_option_returns_true_when_present
    extractor = create_extractor(["analyze", "file.rb", "--format", "json"])
    assert extractor.has_option?("--format")
  end

  def test_has_option_returns_false_when_absent
    extractor = create_extractor(["analyze", "file.rb"])
    refute extractor.has_option?("--format")
  end

  def test_has_any_option_returns_true_when_any_present
    extractor = create_extractor(["analyze", "file.rb", "--stats"])
    assert extractor.has_any_option?("--format", "--stats", "--output")
  end

  def test_has_any_option_returns_false_when_none_present
    extractor = create_extractor(["analyze", "file.rb"])
    refute extractor.has_any_option?("--format", "--stats", "--output")
  end

  private

  def create_extractor(args)
    RailsDependencyExplorer::CLI::OptionExtractor.new(args)
  end
end
