# frozen_string_literal: true

require "minitest/autorun"
require_relative "../test_helper"

class ConsoleFormatAdapterTest < Minitest::Test
  def setup
    # ConsoleFormatAdapter is now a class method, no instantiation needed
  end

  def test_console_format_adapter_formats_single_dependency
    graph_data = {
      nodes: ["Player", "Enemy"],
      edges: [["Player", "Enemy"]]
    }

    result = RailsDependencyExplorer::Output::ConsoleFormatAdapter.format(graph_data)
    expected = <<~OUTPUT.chomp
      Dependencies found:

      Classes: Player, Enemy

      Dependencies:
        Player -> Enemy
    OUTPUT

    assert_equal expected, result
  end

  def test_console_format_adapter_formats_multiple_dependencies
    graph_data = {
      nodes: ["Player", "Enemy", "Logger"],
      edges: [["Player", "Enemy"], ["Player", "Logger"], ["Enemy", "Logger"]]
    }

    result = RailsDependencyExplorer::Output::ConsoleFormatAdapter.format(graph_data)
    expected = <<~OUTPUT.chomp
      Dependencies found:

      Classes: Player, Enemy, Logger

      Dependencies:
        Player -> Enemy
        Player -> Logger
        Enemy -> Logger
    OUTPUT

    assert_equal expected, result
  end

  def test_console_format_adapter_handles_empty_graph
    graph_data = {
      nodes: [],
      edges: []
    }

    result = RailsDependencyExplorer::Output::ConsoleFormatAdapter.format(graph_data)
    expected = "No dependencies found."

    assert_equal expected, result
  end

  def test_console_format_adapter_handles_nodes_without_edges
    graph_data = {
      nodes: ["Player"],
      edges: []
    }

    result = RailsDependencyExplorer::Output::ConsoleFormatAdapter.format(graph_data)
    expected = <<~OUTPUT.chomp
      Dependencies found:

      Classes: Player

      Dependencies:
    OUTPUT

    assert_equal expected, result
  end

  def test_console_format_adapter_formats_complex_dependency_graph
    graph_data = {
      nodes: ["UserService", "UserRepository", "EmailService", "Logger", "User"],
      edges: [
        ["UserService", "UserRepository"],
        ["UserService", "EmailService"],
        ["UserService", "Logger"],
        ["UserService", "User"]
      ]
    }

    result = RailsDependencyExplorer::Output::ConsoleFormatAdapter.format(graph_data)

    assert_includes result, "Dependencies found:"
    assert_includes result, "Classes: UserService, UserRepository, EmailService, Logger, User"
    assert_includes result, "Dependencies:"
    assert_includes result, "  UserService -> UserRepository"
    assert_includes result, "  UserService -> EmailService"
    assert_includes result, "  UserService -> Logger"
    assert_includes result, "  UserService -> User"
  end
end
