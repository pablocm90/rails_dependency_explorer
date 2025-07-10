# frozen_string_literal: true

require "minitest/autorun"
require_relative "../test_helper"

class ActiveRecordRelationshipAnalyzerTest < Minitest::Test
  def setup
    @analyzer = RailsDependencyExplorer::Analysis::ActiveRecordRelationshipAnalyzer.new({})
  end

  def test_analyze_relationships_returns_empty_hash_for_empty_data
    analyzer = RailsDependencyExplorer::Analysis::ActiveRecordRelationshipAnalyzer.new({})
    result = analyzer.analyze_relationships

    assert_equal({}, result)
  end

  def test_analyze_relationships_extracts_belongs_to_relationships
    dependency_data = {
      "User" => [{"ActiveRecord::belongs_to" => ["Account"]}]
    }
    analyzer = RailsDependencyExplorer::Analysis::ActiveRecordRelationshipAnalyzer.new(dependency_data)

    result = analyzer.analyze_relationships

    assert_equal ["Account"], result["User"][:belongs_to]
    assert_empty result["User"][:has_many]
    assert_empty result["User"][:has_one]
    assert_empty result["User"][:has_and_belongs_to_many]
  end

  def test_analyze_relationships_extracts_has_many_relationships
    dependency_data = {
      "User" => [{"ActiveRecord::has_many" => ["Post", "Comment"]}]
    }
    analyzer = RailsDependencyExplorer::Analysis::ActiveRecordRelationshipAnalyzer.new(dependency_data)

    result = analyzer.analyze_relationships

    assert_equal ["Post", "Comment"], result["User"][:has_many]
    assert_empty result["User"][:belongs_to]
    assert_empty result["User"][:has_one]
    assert_empty result["User"][:has_and_belongs_to_many]
  end

  def test_analyze_relationships_extracts_has_one_relationships
    dependency_data = {
      "User" => [{"ActiveRecord::has_one" => ["Profile"]}]
    }
    analyzer = RailsDependencyExplorer::Analysis::ActiveRecordRelationshipAnalyzer.new(dependency_data)

    result = analyzer.analyze_relationships

    assert_equal ["Profile"], result["User"][:has_one]
    assert_empty result["User"][:belongs_to]
    assert_empty result["User"][:has_many]
    assert_empty result["User"][:has_and_belongs_to_many]
  end

  def test_analyze_relationships_extracts_has_and_belongs_to_many_relationships
    dependency_data = {
      "User" => [{"ActiveRecord::has_and_belongs_to_many" => ["Role"]}]
    }
    analyzer = RailsDependencyExplorer::Analysis::ActiveRecordRelationshipAnalyzer.new(dependency_data)

    result = analyzer.analyze_relationships

    assert_equal ["Role"], result["User"][:has_and_belongs_to_many]
    assert_empty result["User"][:belongs_to]
    assert_empty result["User"][:has_many]
    assert_empty result["User"][:has_one]
  end

  def test_analyze_relationships_handles_multiple_relationship_types
    dependency_data = {
      "User" => [
        {"ActiveRecord::belongs_to" => ["Account"]},
        {"ActiveRecord::has_many" => ["Post", "Comment"]},
        {"ActiveRecord::has_one" => ["Profile"]},
        {"ActiveRecord::has_and_belongs_to_many" => ["Role"]}
      ]
    }
    analyzer = RailsDependencyExplorer::Analysis::ActiveRecordRelationshipAnalyzer.new(dependency_data)

    result = analyzer.analyze_relationships

    assert_equal ["Account"], result["User"][:belongs_to]
    assert_equal ["Post", "Comment"], result["User"][:has_many]
    assert_equal ["Profile"], result["User"][:has_one]
    assert_equal ["Role"], result["User"][:has_and_belongs_to_many]
  end

  def test_analyze_relationships_handles_multiple_classes
    dependency_data = {
      "User" => [{"ActiveRecord::belongs_to" => ["Account"]}],
      "Post" => [{"ActiveRecord::belongs_to" => ["User"]}]
    }
    analyzer = RailsDependencyExplorer::Analysis::ActiveRecordRelationshipAnalyzer.new(dependency_data)

    result = analyzer.analyze_relationships

    assert_equal ["Account"], result["User"][:belongs_to]
    assert_equal ["User"], result["Post"][:belongs_to]
  end

  def test_analyze_relationships_ignores_non_activerecord_dependencies
    dependency_data = {
      "User" => [
        {"Logger" => ["info"]},
        {"ActiveRecord::belongs_to" => ["Account"]},
        {"Redis" => ["get"]}
      ]
    }
    analyzer = RailsDependencyExplorer::Analysis::ActiveRecordRelationshipAnalyzer.new(dependency_data)

    result = analyzer.analyze_relationships

    assert_equal ["Account"], result["User"][:belongs_to]
    assert_empty result["User"][:has_many]
    assert_empty result["User"][:has_one]
    assert_empty result["User"][:has_and_belongs_to_many]
  end

  def test_analyze_relationships_handles_classes_without_relationships
    dependency_data = {
      "User" => [{"Logger" => ["info"]}],
      "Post" => [{"ActiveRecord::belongs_to" => ["User"]}]
    }
    analyzer = RailsDependencyExplorer::Analysis::ActiveRecordRelationshipAnalyzer.new(dependency_data)

    result = analyzer.analyze_relationships

    # User should have empty relationship arrays
    assert_empty result["User"][:belongs_to]
    assert_empty result["User"][:has_many]
    assert_empty result["User"][:has_one]
    assert_empty result["User"][:has_and_belongs_to_many]

    # Post should have the relationship
    assert_equal ["User"], result["Post"][:belongs_to]
  end
end
