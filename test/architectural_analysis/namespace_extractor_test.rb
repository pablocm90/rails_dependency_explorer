# frozen_string_literal: true

require "minitest/autorun"
require_relative "../test_helper"
require_relative "../../lib/rails_dependency_explorer/architectural_analysis/namespace_extractor"

# Tests for NamespaceExtractor focusing on parsing Ruby class names
# to extract namespace information for architectural analysis.
class NamespaceExtractorTest < Minitest::Test
  def test_extract_namespace_from_simple_class
    namespace = RailsDependencyExplorer::ArchitecturalAnalysis::NamespaceExtractor.extract_namespace("User")
    assert_equal "", namespace
  end

  def test_extract_namespace_from_single_level_namespace
    namespace = RailsDependencyExplorer::ArchitecturalAnalysis::NamespaceExtractor.extract_namespace("Services::UserService")
    assert_equal "Services", namespace
  end

  def test_extract_namespace_from_multi_level_namespace
    namespace = RailsDependencyExplorer::ArchitecturalAnalysis::NamespaceExtractor.extract_namespace("App::Models::User")
    assert_equal "App::Models", namespace
  end

  def test_extract_namespace_from_deep_namespace
    namespace = RailsDependencyExplorer::ArchitecturalAnalysis::NamespaceExtractor.extract_namespace("App::Services::External::EmailService")
    assert_equal "App::Services::External", namespace
  end

  def test_extract_namespaces_from_cycle_with_mixed_classes
    cycle = ["User", "Services::UserService", "App::Models::Profile", "User"]
    namespaces = RailsDependencyExplorer::ArchitecturalAnalysis::NamespaceExtractor.extract_namespaces_from_cycle(cycle)
    
    expected_namespaces = ["", "Services", "App::Models"]
    assert_equal expected_namespaces, namespaces
  end

  def test_extract_namespaces_from_cycle_removes_duplicates
    cycle = ["App::Models::User", "Services::UserService", "App::Models::Profile", "App::Models::User"]
    namespaces = RailsDependencyExplorer::ArchitecturalAnalysis::NamespaceExtractor.extract_namespaces_from_cycle(cycle)
    
    expected_namespaces = ["App::Models", "Services"]
    assert_equal expected_namespaces, namespaces
  end

  def test_extract_namespaces_from_cycle_ignores_duplicate_last_element
    cycle = ["App::Models::User", "Services::UserService", "App::Models::User"]
    namespaces = RailsDependencyExplorer::ArchitecturalAnalysis::NamespaceExtractor.extract_namespaces_from_cycle(cycle)
    
    # Should only consider unique classes, ignoring the cycle completion duplicate
    expected_namespaces = ["App::Models", "Services"]
    assert_equal expected_namespaces, namespaces
  end
end
