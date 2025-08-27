# frozen_string_literal: true

require "test_helper"
require_relative "../../lib/rails_dependency_explorer/parsing/base_node_handler"
require_relative "../../lib/rails_dependency_explorer/analysis/graph_processor"
require_relative "../../lib/rails_dependency_explorer/output/format_adapter_interface"

# Test to demonstrate the extracted missing abstractions
# Shows how common functionality has been extracted into shared base classes and modules
class MissingAbstractionsTest < Minitest::Test
  def test_base_node_handler_provides_common_functionality
    # GREEN: This test demonstrates that BaseNodeHandler provides common functionality
    # for all node handlers, reducing duplication
    
    # Create a mock node for testing
    mock_node = create_mock_node(:const, ["Module", "Class"])
    
    # Test common validation
    # Should not raise an error for valid node
    RailsDependencyExplorer::Parsing::BaseNodeHandler.send(:validate_node, mock_node)
    
    # Test safe child access
    first_child = RailsDependencyExplorer::Parsing::BaseNodeHandler.send(:safe_child, mock_node, 0)
    assert_equal "Module", first_child
    
    second_child = RailsDependencyExplorer::Parsing::BaseNodeHandler.send(:safe_child, mock_node, 1)
    assert_equal "Class", second_child
    
    # Test out of bounds access
    nil_child = RailsDependencyExplorer::Parsing::BaseNodeHandler.send(:safe_child, mock_node, 5)
    assert_nil nil_child
  end

  def test_base_node_handler_provides_string_extraction
    # Test child_string helper method
    mock_node = create_mock_node(:const, ["Module", :Class])
    
    string_child = RailsDependencyExplorer::Parsing::BaseNodeHandler.send(:child_string, mock_node, 0)
    assert_equal "Module", string_child
    
    symbol_child = RailsDependencyExplorer::Parsing::BaseNodeHandler.send(:child_string, mock_node, 1)
    assert_equal "Class", symbol_child
  end

  def test_base_node_handler_provides_type_checking
    # Test child_type? helper method
    mock_const_node = create_mock_node(:const, ["Module"])
    mock_send_node = create_mock_node(:send, [mock_const_node, "method"])
    
    # Test type checking
    is_const = RailsDependencyExplorer::Parsing::BaseNodeHandler.send(:child_type?, mock_send_node, 0, :const)
    assert is_const
    
    is_send = RailsDependencyExplorer::Parsing::BaseNodeHandler.send(:child_type?, mock_send_node, 0, :send)
    refute is_send
  end

  def test_base_node_handler_provides_constant_processing
    # Test constant name extraction helpers
    mock_nested_const = create_nested_const_node("Config", "MAX_HEALTH")
    
    parts = RailsDependencyExplorer::Parsing::BaseNodeHandler.send(:extract_constant_parts, mock_nested_const)
    assert_equal ["Config", "MAX_HEALTH"], parts
    
    full_name = RailsDependencyExplorer::Parsing::BaseNodeHandler.send(:build_constant_name, parts)
    assert_equal "Config::MAX_HEALTH", full_name
  end

  def test_base_node_handler_provides_activerecord_helpers
    # Test ActiveRecord relationship detection
    is_belongs_to = RailsDependencyExplorer::Parsing::BaseNodeHandler.send(:activerecord_relationship_method?, "belongs_to")
    assert is_belongs_to
    
    is_regular_method = RailsDependencyExplorer::Parsing::BaseNodeHandler.send(:activerecord_relationship_method?, "regular_method")
    refute is_regular_method
    
    # Test symbol to model name conversion
    model_name = RailsDependencyExplorer::Parsing::BaseNodeHandler.send(:symbol_to_model_name, ":posts")
    assert_equal "Post", model_name
    
    model_name2 = RailsDependencyExplorer::Parsing::BaseNodeHandler.send(:symbol_to_model_name, "categories")
    assert_equal "Category", model_name2
  end

  def test_graph_processor_provides_common_graph_operations
    # GREEN: This test demonstrates that GraphProcessor provides common graph operations
    # reducing duplication across analyzers and adapters
    
    dependency_data = {
      "Player" => [{"Enemy" => ["health"]}, {"Logger" => ["info"]}],
      "Enemy" => [{"Player" => ["attack"]}]
    }
    
    # Test node extraction
    nodes = RailsDependencyExplorer::Analysis::GraphProcessor.extract_nodes(dependency_data)
    expected_nodes = ["Player", "Enemy", "Logger"]
    assert_equal expected_nodes.sort, nodes.to_a.sort
    
    # Test edge extraction
    edges = RailsDependencyExplorer::Analysis::GraphProcessor.extract_edges(dependency_data)
    expected_edges = [["Player", "Enemy"], ["Player", "Logger"], ["Enemy", "Player"]]
    assert_equal expected_edges.sort, edges.to_a.sort
    
    # Test adjacency list building
    adjacency_list = RailsDependencyExplorer::Analysis::GraphProcessor.build_adjacency_list(dependency_data)
    assert_equal ["Enemy", "Logger"], adjacency_list["Player"].sort
    assert_equal ["Player"], adjacency_list["Enemy"]
  end

  def test_graph_processor_provides_dependency_analysis
    # Test dependency analysis helpers
    dependency_data = {
      "Player" => [{"Enemy" => ["health"]}, {"Logger" => ["info"]}],
      "Game" => [{"Player" => ["new"]}, {"Logger" => ["debug"]}]
    }
    
    # Test dependencies for specific class
    player_deps = RailsDependencyExplorer::Analysis::GraphProcessor.dependencies_for_class(dependency_data, "Player")
    assert_equal ["Enemy", "Logger"], player_deps.sort
    
    # Test total dependency count
    total_deps = RailsDependencyExplorer::Analysis::GraphProcessor.count_total_dependencies(dependency_data)
    assert_equal 3, total_deps # Enemy, Logger, Player
    
    # Test most used dependency
    most_used = RailsDependencyExplorer::Analysis::GraphProcessor.most_used_dependency(dependency_data)
    assert_equal "Logger", most_used # Logger is used by both Player and Game
  end

  def test_graph_processor_provides_filtering_capabilities
    # Test dependency filtering
    dependency_data = {
      "User" => [
        {"ApplicationRecord" => ["save"]},
        {"ActiveRecord::belongs_to" => ["Account"]},
        {"Logger" => ["info"]}
      ]
    }
    
    # Filter out ActiveRecord relationships
    filtered = RailsDependencyExplorer::Analysis::GraphProcessor.filter_dependencies(dependency_data) do |_class_name, constant_name|
      !constant_name.start_with?("ActiveRecord::")
    end
    
    user_deps = filtered["User"]
    assert_equal 2, user_deps.size # ApplicationRecord and Logger, not ActiveRecord::belongs_to
    
    # Verify ActiveRecord relationship was filtered out
    has_ar_relationship = user_deps.any? { |dep| dep.key?("ActiveRecord::belongs_to") }
    refute has_ar_relationship
  end

  def test_format_adapter_interface_provides_common_functionality
    # GREEN: This test demonstrates that FormatAdapterInterface provides common functionality
    # for all format adapters, reducing duplication
    
    # Create a test adapter that includes the interface
    test_adapter = Class.new do
      include RailsDependencyExplorer::Output::FormatAdapterInterface
      
      def format_content(dependency_data, statistics = {})
        "Test format: #{dependency_data.keys.join(', ')}"
      end
    end.new
    
    dependency_data = {"Player" => [{"Enemy" => ["health"]}]}
    
    # Test that the template method works
    result = test_adapter.format(dependency_data)
    assert_equal "Test format: Player", result
    
    # Test validation
    assert_raises(ArgumentError) do
      test_adapter.format("not a hash")
    end
  end

  def test_format_adapter_interface_provides_common_helpers
    # Test common helper methods in FormatAdapterInterface
    test_adapter = Class.new do
      include RailsDependencyExplorer::Output::FormatAdapterInterface
      
      def format_content(dependency_data, statistics = {})
        # Use the common helpers
        deps = extract_dependencies(dependency_data)
        nodes = extract_nodes(dependency_data)
        edges = extract_edges(dependency_data)
        
        "Dependencies: #{deps.keys.size}, Nodes: #{nodes.size}, Edges: #{edges.size}"
      end
    end.new
    
    dependency_data = {
      "Player" => [{"Enemy" => ["health"]}, {"Enemy" => ["damage"]}],
      "Game" => [{"Player" => ["new"]}]
    }
    
    result = test_adapter.format(dependency_data)
    assert_equal "Dependencies: 2, Nodes: 3, Edges: 3", result
  end

  private

  def create_mock_node(type, children)
    mock_node = Object.new
    mock_node.define_singleton_method(:type) { type }
    mock_node.define_singleton_method(:children) { children }
    mock_node
  end

  def create_nested_const_node(parent_name, child_name)
    parent_node = create_mock_node(:const, [nil, parent_name.to_sym])
    create_mock_node(:const, [parent_node, child_name.to_sym])
  end
end
