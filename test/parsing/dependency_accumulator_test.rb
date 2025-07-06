# frozen_string_literal: true

require "minitest/autorun"
require_relative "../test_helper"

class DependencyAccumulatorTest < Minitest::Test
  def setup
    @accumulator = RailsDependencyExplorer::Parsing::DependencyAccumulator.new
  end

  def test_initialize_creates_empty_collection
    result = @accumulator.collection.to_grouped_array
    expected = []

    assert_equal expected, result
  end

  def test_record_method_call_adds_to_collection
    @accumulator.record_method_call("Enemy", "health")

    result = @accumulator.collection.to_grouped_array
    expected = [{"Enemy" => ["health"]}]

    assert_equal expected, result
  end

  def test_record_constant_access_adds_to_collection
    @accumulator.record_constant_access("Config", "MAX_HEALTH")

    result = @accumulator.collection.to_grouped_array
    expected = [{"Config" => ["MAX_HEALTH"]}]

    assert_equal expected, result
  end

  def test_accumulate_processes_multiple_method_calls
    @accumulator.record_method_call("Enemy", "health")
    @accumulator.record_method_call("Enemy", "take_damage")
    @accumulator.record_constant_access("Config", "MAX_HEALTH")

    result = @accumulator.collection.to_grouped_array

    # Check that all dependencies are accumulated correctly
    assert_equal 2, result.length
    assert_includes result, {"Enemy" => ["health", "take_damage"]}
    assert_includes result, {"Config" => ["MAX_HEALTH"]}
  end
end
