# frozen_string_literal: true

require "minitest/autorun"
require_relative "../test_helper"
require_relative "../../lib/rails_dependency_explorer/output/rails_aware_graph_adapter"

class RailsAwareGraphAdapterTest < Minitest::Test
  def setup
    @adapter = RailsDependencyExplorer::Output::RailsAwareGraphAdapter.new
  end

  def test_handles_regular_dependencies_like_standard_adapter
    dependency_data = {"Player" => [{"Enemy" => ["health"]}]}

    result = @adapter.to_graph(dependency_data)
    expected = {
      nodes: ["Player", "Enemy"],
      edges: [["Player", "Enemy"]]
    }

    assert_equal expected, result
  end

  def test_converts_activerecord_belongs_to_to_model_relationship
    dependency_data = {
      "User" => [{"ActiveRecord::belongs_to" => ["Account"]}]
    }

    result = @adapter.to_graph(dependency_data)
    expected = {
      nodes: ["User", "Account"],
      edges: [["User", "Account"]]
    }

    assert_equal expected, result
  end

  def test_converts_activerecord_has_many_to_model_relationships
    dependency_data = {
      "User" => [{"ActiveRecord::has_many" => ["Post", "Comment"]}]
    }

    result = @adapter.to_graph(dependency_data)

    expected_nodes = ["User", "Post", "Comment"]
    expected_edges = [["User", "Post"], ["User", "Comment"]]

    assert_equal expected_nodes.sort, result[:nodes].sort
    assert_equal expected_edges.sort, result[:edges].sort
  end

  def test_handles_multiple_activerecord_relationship_types
    dependency_data = {
      "User" => [
        {"ActiveRecord::belongs_to" => ["Account"]},
        {"ActiveRecord::has_many" => ["Post", "Comment"]},
        {"ActiveRecord::has_one" => ["Profile"]},
        {"ActiveRecord::has_and_belongs_to_many" => ["Role"]}
      ]
    }

    result = @adapter.to_graph(dependency_data)

    expected_nodes = ["User", "Account", "Post", "Comment", "Profile", "Role"]
    expected_edges = [
      ["User", "Account"],
      ["User", "Post"],
      ["User", "Comment"],
      ["User", "Profile"],
      ["User", "Role"]
    ]

    assert_equal expected_nodes.sort, result[:nodes].sort
    assert_equal expected_edges.sort, result[:edges].sort
  end

  def test_combines_regular_dependencies_with_activerecord_relationships
    dependency_data = {
      "User" => [
        {"ApplicationRecord" => [[]]},
        {"ActiveRecord::belongs_to" => ["Account"]},
        {"ActiveRecord::has_many" => ["Post"]},
        {"Logger" => ["info"]}
      ]
    }

    result = @adapter.to_graph(dependency_data)

    expected_nodes = ["User", "ApplicationRecord", "Account", "Post", "Logger"]
    expected_edges = [
      ["User", "ApplicationRecord"],
      ["User", "Account"],
      ["User", "Post"],
      ["User", "Logger"]
    ]

    assert_equal expected_nodes.sort, result[:nodes].sort
    assert_equal expected_edges.sort, result[:edges].sort
  end

  def test_handles_multiple_classes_with_mixed_dependencies
    dependency_data = {
      "User" => [
        {"ApplicationRecord" => [[]]},
        {"ActiveRecord::belongs_to" => ["Account"]},
        {"ActiveRecord::has_many" => ["Post"]}
      ],
      "Post" => [
        {"ApplicationRecord" => [[]]},
        {"ActiveRecord::belongs_to" => ["User"]},
        {"ActiveRecord::has_many" => ["Comment"]}
      ]
    }

    result = @adapter.to_graph(dependency_data)

    expected_nodes = ["User", "Post", "ApplicationRecord", "Account", "Comment"]
    expected_edges = [
      ["User", "ApplicationRecord"],
      ["User", "Account"],
      ["User", "Post"],
      ["Post", "ApplicationRecord"],
      ["Post", "User"],
      ["Post", "Comment"]
    ]

    assert_equal expected_nodes.sort, result[:nodes].sort
    assert_equal expected_edges.sort, result[:edges].sort
  end

  def test_deduplicates_nodes_and_edges
    dependency_data = {
      "User" => [{"ActiveRecord::belongs_to" => ["Account"]}],
      "Post" => [{"ActiveRecord::belongs_to" => ["Account"]}]
    }

    result = @adapter.to_graph(dependency_data)

    expected_nodes = ["User", "Post", "Account"]
    expected_edges = [["User", "Account"], ["Post", "Account"]]

    assert_equal expected_nodes.sort, result[:nodes].sort
    assert_equal expected_edges.sort, result[:edges].sort
  end

  def test_handles_empty_dependency_data
    dependency_data = {}

    result = @adapter.to_graph(dependency_data)
    expected = {
      nodes: [],
      edges: []
    }

    assert_equal expected, result
  end

  def test_handles_class_with_no_dependencies
    dependency_data = {"Player" => []}

    result = @adapter.to_graph(dependency_data)
    expected = {
      nodes: ["Player"],
      edges: []
    }

    assert_equal expected, result
  end
end
