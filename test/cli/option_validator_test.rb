# frozen_string_literal: true

require "test_helper"

class OptionValidatorTest < Minitest::Test
  def setup
    @validator = RailsDependencyExplorer::CLI::OptionValidator.new
  end

  def test_validate_format_returns_default_for_nil
    result = @validator.validate_format(nil)
    assert result[:valid]
    assert_equal "graph", result[:value]
    assert_nil result[:error]
  end

  def test_validate_format_returns_valid_format
    result = @validator.validate_format("json")
    assert result[:valid]
    assert_equal "json", result[:value]
    assert_nil result[:error]
  end

  def test_validate_format_returns_error_for_invalid_format
    result = @validator.validate_format("invalid")
    refute result[:valid]
    assert_nil result[:value]
    assert_equal "Error: Invalid format 'invalid'", result[:error][:message]
    assert_includes result[:error][:details], "dot, json, html, graph"
  end

  def test_validate_format_returns_error_for_missing_value
    result = @validator.validate_format(:missing)
    refute result[:valid]
    assert_nil result[:value]
    assert_equal "Error: --format option requires a format value", result[:error][:message]
    assert_includes result[:error][:details], "dot, json, html, graph"
  end

  def test_validate_output_returns_nil_for_nil
    result = @validator.validate_output(nil)
    assert result[:valid]
    assert_nil result[:value]
    assert_nil result[:error]
  end

  def test_validate_output_returns_valid_output_file
    result = @validator.validate_output("result.json")
    assert result[:valid]
    assert_equal "result.json", result[:value]
    assert_nil result[:error]
  end

  def test_validate_output_returns_error_for_missing_value
    result = @validator.validate_output(:missing)
    refute result[:valid]
    assert_nil result[:value]
    assert_equal "Error: --output option requires a file path", result[:error][:message]
    assert_nil result[:error][:details]
  end

  def test_validate_directory_returns_nil_for_nil
    result = @validator.validate_directory(nil)
    assert result[:valid]
    assert_nil result[:value]
    assert_nil result[:error]
  end

  def test_validate_directory_returns_valid_directory_path
    result = @validator.validate_directory("app/models")
    assert result[:valid]
    assert_equal "app/models", result[:value]
    assert_nil result[:error]
  end

  def test_validate_directory_returns_error_for_missing_value
    result = @validator.validate_directory(:missing)
    refute result[:valid]
    assert_nil result[:value]
    assert_equal "Error: --directory option requires a directory path", result[:error][:message]
    assert_nil result[:error][:details]
  end

  def test_valid_formats_constant_includes_expected_formats
    expected_formats = ["dot", "json", "html", "graph"]
    assert_equal expected_formats, RailsDependencyExplorer::CLI::OptionValidator::VALID_FORMATS
  end
end
