# frozen_string_literal: true

require "minitest/autorun"
require_relative "../test_helper"

class RailsConfigurationAnalyzerTest < Minitest::Test
  def test_rails_configuration_analyzer_categorizes_rails_dependencies
    dependency_data = {
      "ConfigService" => [
        {"Rails" => ["logger", "env", "application", "root", "cache"]},
        {"ENV" => ["[]"]}
      ]
    }

    analyzer = RailsDependencyExplorer::Analysis::Analyzers::RailsConfigurationAnalyzer.new(dependency_data)
    result = analyzer.analyze_configuration_dependencies

    expected = {
      "ConfigService" => {
        rails_config: ["Rails.logger", "Rails.env", "Rails.application.config", "Rails.root", "Rails.cache"],
        environment_variables: ["ENV"],
        secrets_and_credentials: []
      }
    }

    assert_equal expected, result
  end

  def test_rails_configuration_analyzer_handles_empty_dependencies
    dependency_data = {
      "EmptyService" => []
    }

    analyzer = RailsDependencyExplorer::Analysis::Analyzers::RailsConfigurationAnalyzer.new(dependency_data)
    result = analyzer.analyze_configuration_dependencies

    expected = {
      "EmptyService" => {
        rails_config: [],
        environment_variables: [],
        secrets_and_credentials: []
      }
    }

    assert_equal expected, result
  end

  def test_rails_configuration_analyzer_handles_non_rails_dependencies
    dependency_data = {
      "RegularService" => [
        {"Logger" => ["info"]},
        {"Database" => ["connect"]}
      ]
    }

    analyzer = RailsDependencyExplorer::Analysis::Analyzers::RailsConfigurationAnalyzer.new(dependency_data)
    result = analyzer.analyze_configuration_dependencies

    expected = {
      "RegularService" => {
        rails_config: [],
        environment_variables: [],
        secrets_and_credentials: []
      }
    }

    assert_equal expected, result
  end

  def test_rails_configuration_analyzer_deduplicates_dependencies
    dependency_data = {
      "DuplicateService" => [
        {"Rails" => ["logger", "env"]},
        {"Rails" => ["logger", "cache"]},  # Duplicate logger
        {"ENV" => ["[]"]},
        {"ENV" => ["[]"]}  # Duplicate ENV
      ]
    }

    analyzer = RailsDependencyExplorer::Analysis::Analyzers::RailsConfigurationAnalyzer.new(dependency_data)
    result = analyzer.analyze_configuration_dependencies

    expected = {
      "DuplicateService" => {
        rails_config: ["Rails.logger", "Rails.env", "Rails.cache"],
        environment_variables: ["ENV"],
        secrets_and_credentials: []
      }
    }

    assert_equal expected, result
  end
end
