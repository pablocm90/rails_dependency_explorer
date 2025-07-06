# frozen_string_literal: true

require "minitest/autorun"
require_relative "../test_helper"

class DependencyCollectionTest < Minitest::Test
  def setup
    @collection = RailsDependencyExplorer::Analysis::DependencyCollection.new
  end

  def test_add_method_call_adds_new_constant_and_method
    @collection.add_method_call("Enemy", "health")

    result = @collection.to_grouped_array
    expected = [{"Enemy" => ["health"]}]

    assert_equal expected, result
  end

  def test_add_method_call_adds_multiple_methods_to_same_constant
    @collection.add_method_call("Enemy", "health")
    @collection.add_method_call("Enemy", "take_damage")

    result = @collection.to_grouped_array
    expected = [{"Enemy" => ["health", "take_damage"]}]

    assert_equal expected, result
  end

  def test_add_method_call_prevents_duplicate_methods
    @collection.add_method_call("Enemy", "health")
    @collection.add_method_call("Enemy", "health")

    result = @collection.to_grouped_array
    expected = [{"Enemy" => ["health"]}]

    assert_equal expected, result
  end

  def test_add_constant_access_delegates_to_add_method_call
    @collection.add_constant_access("Config", "MAX_HEALTH")

    result = @collection.to_grouped_array
    expected = [{"Config" => ["MAX_HEALTH"]}]

    assert_equal expected, result
  end

  def test_merge_hash_dependency_merges_single_constant
    hash_dep = {"Logger" => ["info", "debug"]}
    @collection.merge_hash_dependency(hash_dep)

    result = @collection.to_grouped_array
    expected = [{"Logger" => ["info", "debug"]}]

    assert_equal expected, result
  end

  def test_merge_hash_dependency_merges_with_existing_constant
    @collection.add_method_call("Enemy", "health")
    hash_dep = {"Enemy" => ["take_damage"]}
    @collection.merge_hash_dependency(hash_dep)

    result = @collection.to_grouped_array
    expected = [{"Enemy" => ["health", "take_damage"]}]

    assert_equal expected, result
  end

  def test_merge_hash_dependency_prevents_duplicates
    @collection.add_method_call("Enemy", "health")
    hash_dep = {"Enemy" => ["health", "take_damage"]}
    @collection.merge_hash_dependency(hash_dep)

    result = @collection.to_grouped_array
    expected = [{"Enemy" => ["health", "take_damage"]}]

    assert_equal expected, result
  end

  def test_to_grouped_array_returns_empty_array_for_empty_collection
    result = @collection.to_grouped_array
    expected = []

    assert_equal expected, result
  end

  def test_to_grouped_array_handles_multiple_constants
    @collection.add_method_call("Enemy", "health")
    @collection.add_method_call("Logger", "info")
    @collection.add_method_call("Config", "MAX_HEALTH")

    result = @collection.to_grouped_array

    # Since hash order isn't guaranteed, check that all expected entries are present
    assert_equal 3, result.length
    assert_includes result, {"Enemy" => ["health"]}
    assert_includes result, {"Logger" => ["info"]}
    assert_includes result, {"Config" => ["MAX_HEALTH"]}
  end
end
