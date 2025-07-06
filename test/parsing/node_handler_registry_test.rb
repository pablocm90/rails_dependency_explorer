# frozen_string_literal: true

require "minitest/autorun"
require_relative "../test_helper"

class NodeHandlerRegistryTest < Minitest::Test
  def setup
    @registry = RailsDependencyExplorer::Parsing::NodeHandlerRegistry.new
  end

  def test_initialize_creates_empty_registry
    assert_empty @registry.handlers
  end

  def test_register_adds_handler_for_node_type
    handler = proc { |node| "handled" }
    @registry.register(:const, handler)

    assert_equal handler, @registry.handlers[:const]
  end

  def test_handle_calls_registered_handler
    handler = proc { |node| "handled: #{node}" }
    @registry.register(:const, handler)

    result = @registry.handle(:const, "test_node")
    expected = "handled: test_node"

    assert_equal expected, result
  end

  def test_handle_returns_nil_for_unregistered_node_type
    result = @registry.handle(:unknown, "test_node")

    assert_nil result
  end

  def test_registered_returns_true_for_registered_handler
    handler = proc { |node| "handled" }
    @registry.register(:const, handler)

    assert @registry.registered?(:const)
    refute @registry.registered?(:unknown)
  end
end
