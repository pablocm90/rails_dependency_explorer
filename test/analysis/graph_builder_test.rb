require "test_helper"
require "rails_dependency_explorer/analysis/graph_builder"

module RailsDependencyExplorer
  module Analysis
    class GraphBuilderTest < Minitest::Test
      def test_build_adjacency_list_with_hash_dependencies
        dependency_data = {
          "UserService" => [
            {"User" => ["find", "create"]},
            {"Database" => ["connect"]}
          ],
          "OrderService" => [
            {"Order" => ["save"]},
            {"User" => ["find"]}
          ]
        }

        graph = GraphBuilder.build_adjacency_list(dependency_data)

        expected_graph = {
          "UserService" => ["User", "Database"],
          "OrderService" => ["Order", "User"]
        }

        assert_equal expected_graph, graph
      end

      def test_build_adjacency_list_avoids_duplicates
        dependency_data = {
          "TestClass" => [
            {"Helper" => ["method1"]},
            {"Helper" => ["method2"]}
          ]
        }

        graph = GraphBuilder.build_adjacency_list(dependency_data)

        expected_graph = {
          "TestClass" => ["Helper"]
        }

        assert_equal expected_graph, graph
      end

      def test_build_adjacency_list_with_empty_data
        dependency_data = {}

        graph = GraphBuilder.build_adjacency_list(dependency_data)

        assert_equal({}, graph)
      end

      def test_build_adjacency_list_ignores_non_hash_dependencies
        dependency_data = {
          "TestClass" => [
            {"ValidDep" => ["method"]},
            "InvalidDep",
            nil
          ]
        }

        graph = GraphBuilder.build_adjacency_list(dependency_data)

        expected_graph = {
          "TestClass" => ["ValidDep"]
        }

        assert_equal expected_graph, graph
      end
    end
  end
end
