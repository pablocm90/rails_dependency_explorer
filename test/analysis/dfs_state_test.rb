# frozen_string_literal: true

require "minitest/autorun"
require_relative "../test_helper"
require_relative "../../lib/rails_dependency_explorer/analysis/dfs_state"

class DfsStateTest < Minitest::Test
  def setup
    @state = RailsDependencyExplorer::Analysis::DfsState.new
  end

  def test_initializes_with_empty_collections
    assert_empty @state.visited
    assert_empty @state.rec_stack
    assert_empty @state.path
    assert_empty @state.cycles
  end

  def test_mark_node_as_visited_adds_to_all_collections
    @state.mark_node_as_visited("A")

    assert @state.node_visited?("A")
    assert @state.node_in_recursion_stack?("A")
    assert_equal ["A"], @state.path
  end

  def test_unmark_node_removes_from_rec_stack_and_path
    @state.mark_node_as_visited("A")
    @state.mark_node_as_visited("B")
    @state.unmark_node("B")

    assert @state.node_visited?("A")
    assert @state.node_visited?("B")
    assert @state.node_in_recursion_stack?("A")
    refute @state.node_in_recursion_stack?("B")
    assert_equal ["A"], @state.path
  end

  def test_extract_cycle_creates_cycle_from_path
    @state.mark_node_as_visited("A")
    @state.mark_node_as_visited("B")
    @state.mark_node_as_visited("C")
    
    @state.extract_cycle("B")
    
    expected_cycle = ["B", "C", "B"]
    assert_equal [expected_cycle], @state.cycles
  end

  def test_extract_cycle_handles_missing_neighbor
    @state.mark_node_as_visited("A")
    @state.mark_node_as_visited("B")
    
    @state.extract_cycle("C")
    
    assert_empty @state.cycles
  end

  def test_extract_cycle_avoids_duplicate_cycles
    @state.mark_node_as_visited("A")
    @state.mark_node_as_visited("B")
    
    @state.extract_cycle("A")
    @state.extract_cycle("A")
    
    expected_cycle = ["A", "B", "A"]
    assert_equal [expected_cycle], @state.cycles
  end

  def test_node_visited_returns_correct_status
    refute @state.node_visited?("A")
    
    @state.mark_node_as_visited("A")
    assert @state.node_visited?("A")
  end

  def test_node_in_recursion_stack_returns_correct_status
    refute @state.node_in_recursion_stack?("A")
    
    @state.mark_node_as_visited("A")
    assert @state.node_in_recursion_stack?("A")
    
    @state.unmark_node("A")
    refute @state.node_in_recursion_stack?("A")
  end
end
