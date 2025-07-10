# frozen_string_literal: true

require "minitest/autorun"
require_relative "../test_helper"

class RailsComponentAnalyzerTest < Minitest::Test
  def setup
    @analyzer = RailsDependencyExplorer::Analysis::RailsComponentAnalyzer.new({})
  end

  def test_categorize_components_identifies_models_by_inheritance
    dependency_data = {
      "User" => [{"ApplicationRecord" => [[]]}],
      "Post" => [{"ApplicationRecord" => [[]]}]
    }
    analyzer = RailsDependencyExplorer::Analysis::RailsComponentAnalyzer.new(dependency_data)
    
    result = analyzer.categorize_components
    
    assert_includes result[:models], "User"
    assert_includes result[:models], "Post"
  end

  def test_categorize_components_identifies_controllers_by_inheritance
    dependency_data = {
      "UsersController" => [{"ApplicationController" => [[]]}],
      "PostsController" => [{"ApplicationController" => [[]]}]
    }
    analyzer = RailsDependencyExplorer::Analysis::RailsComponentAnalyzer.new(dependency_data)
    
    result = analyzer.categorize_components
    
    assert_includes result[:controllers], "UsersController"
    assert_includes result[:controllers], "PostsController"
  end

  def test_categorize_components_identifies_controllers_by_name_pattern
    dependency_data = {
      "AdminController" => [],
      "ApiController" => []
    }
    analyzer = RailsDependencyExplorer::Analysis::RailsComponentAnalyzer.new(dependency_data)
    
    result = analyzer.categorize_components
    
    assert_includes result[:controllers], "AdminController"
    assert_includes result[:controllers], "ApiController"
  end

  def test_categorize_components_identifies_services_by_name_pattern
    dependency_data = {
      "UserService" => [],
      "EmailService" => [],
      "PaymentService" => []
    }
    analyzer = RailsDependencyExplorer::Analysis::RailsComponentAnalyzer.new(dependency_data)
    
    result = analyzer.categorize_components
    
    assert_includes result[:services], "UserService"
    assert_includes result[:services], "EmailService"
    assert_includes result[:services], "PaymentService"
  end

  def test_categorize_components_identifies_other_components
    dependency_data = {
      "Logger" => [],
      "Redis" => [],
      "CustomClass" => []
    }
    analyzer = RailsDependencyExplorer::Analysis::RailsComponentAnalyzer.new(dependency_data)
    
    result = analyzer.categorize_components
    
    assert_includes result[:other], "Logger"
    assert_includes result[:other], "Redis"
    assert_includes result[:other], "CustomClass"
  end

  def test_categorize_components_includes_referenced_dependencies
    dependency_data = {
      "UserService" => [
        {"Logger" => ["info"]},
        {"Redis" => ["new"]}
      ]
    }
    analyzer = RailsDependencyExplorer::Analysis::RailsComponentAnalyzer.new(dependency_data)
    
    result = analyzer.categorize_components
    
    assert_includes result[:services], "UserService"
    assert_includes result[:other], "Logger"
    assert_includes result[:other], "Redis"
  end

  def test_categorize_components_handles_empty_dependency_data
    dependency_data = {}
    analyzer = RailsDependencyExplorer::Analysis::RailsComponentAnalyzer.new(dependency_data)
    
    result = analyzer.categorize_components
    
    assert_equal [], result[:models]
    assert_equal [], result[:controllers]
    assert_equal [], result[:services]
    assert_equal [], result[:other]
  end

  def test_categorize_components_avoids_duplicate_entries
    dependency_data = {
      "UserService" => [{"UserService" => ["call"]}] # Self-reference
    }
    analyzer = RailsDependencyExplorer::Analysis::RailsComponentAnalyzer.new(dependency_data)
    
    result = analyzer.categorize_components
    
    # UserService should only appear once
    assert_equal 1, result[:services].count("UserService")
  end
end
