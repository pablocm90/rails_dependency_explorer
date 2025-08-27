# frozen_string_literal: true

require 'test_helper'
require_relative '../../lib/rails_dependency_explorer/analysis/interfaces/graph_analyzer_interface'

class GraphAnalyzerInterfaceTest < Minitest::Test
  def test_graph_analyzer_interface_exists
    # Interface should be defined
    assert_kind_of Module, RailsDependencyExplorer::Analysis::Interfaces::GraphAnalyzerInterface
  end

  def test_graph_analyzer_interface_defines_required_methods
    interface = RailsDependencyExplorer::Analysis::Interfaces::GraphAnalyzerInterface
    
    # Should define method requirements for graph analysis
    assert_respond_to interface, :included
    
    # When included, should add required methods
    test_class = Class.new do
      include RailsDependencyExplorer::Analysis::Interfaces::GraphAnalyzerInterface
    end
    
    instance = test_class.new
    
    # Should require build_adjacency_list method
    assert_respond_to instance, :build_adjacency_list
    
    # Should require graph analysis capabilities
    assert_respond_to instance, :analyze_graph_structure
  end

  def test_graph_analyzer_interface_provides_graph_utilities
    test_class = Class.new do
      include RailsDependencyExplorer::Analysis::Interfaces::GraphAnalyzerInterface
      
      def initialize(dependency_data)
        @dependency_data = dependency_data
      end
    end
    
    dependency_data = {
      "A" => [{"B" => ["method1"]}, {"C" => ["method2"]}],
      "B" => [{"C" => ["method3"]}],
      "C" => []
    }
    
    instance = test_class.new(dependency_data)
    
    # Should build adjacency list from dependency data
    adjacency_list = instance.build_adjacency_list
    
    assert_kind_of Hash, adjacency_list
    assert_equal ["B", "C"], adjacency_list["A"]
    assert_equal ["C"], adjacency_list["B"]
    assert_equal [], adjacency_list["C"]
  end

  def test_graph_analyzer_interface_provides_structure_analysis
    test_class = Class.new do
      include RailsDependencyExplorer::Analysis::Interfaces::GraphAnalyzerInterface
      
      def initialize(dependency_data)
        @dependency_data = dependency_data
      end
    end
    
    dependency_data = {
      "A" => [{"B" => ["method1"]}],
      "B" => [{"C" => ["method2"]}],
      "C" => []
    }
    
    instance = test_class.new(dependency_data)
    
    # Should analyze graph structure
    structure = instance.analyze_graph_structure
    
    assert_kind_of Hash, structure
    assert_includes structure.keys, :nodes
    assert_includes structure.keys, :edges
    assert_includes structure.keys, :components
    
    # Should identify nodes and edges
    assert_equal 3, structure[:nodes]
    assert_equal 2, structure[:edges]
    assert_equal 1, structure[:components]
  end

  def test_graph_analyzer_interface_handles_empty_data
    test_class = Class.new do
      include RailsDependencyExplorer::Analysis::Interfaces::GraphAnalyzerInterface
      
      def initialize(dependency_data)
        @dependency_data = dependency_data
      end
    end
    
    instance = test_class.new({})
    
    # Should handle empty dependency data gracefully
    adjacency_list = instance.build_adjacency_list
    assert_equal({}, adjacency_list)
    
    structure = instance.analyze_graph_structure
    assert_equal 0, structure[:nodes]
    assert_equal 0, structure[:edges]
    assert_equal 0, structure[:components]
  end

  def test_graph_analyzer_interface_detects_cycles
    test_class = Class.new do
      include RailsDependencyExplorer::Analysis::Interfaces::GraphAnalyzerInterface
      
      def initialize(dependency_data)
        @dependency_data = dependency_data
      end
    end
    
    # Cyclic dependency data
    dependency_data = {
      "A" => [{"B" => ["method1"]}],
      "B" => [{"C" => ["method2"]}],
      "C" => [{"A" => ["method3"]}]
    }
    
    instance = test_class.new(dependency_data)
    
    # Should detect cycles in graph
    structure = instance.analyze_graph_structure
    assert_includes structure.keys, :has_cycles
    assert_equal true, structure[:has_cycles]
  end

  def test_graph_analyzer_interface_identifies_strongly_connected_components
    test_class = Class.new do
      include RailsDependencyExplorer::Analysis::Interfaces::GraphAnalyzerInterface
      
      def initialize(dependency_data)
        @dependency_data = dependency_data
      end
    end
    
    # Complex graph with multiple components
    dependency_data = {
      "A" => [{"B" => ["method1"]}],
      "B" => [{"A" => ["method2"]}],  # Cycle A-B
      "C" => [{"D" => ["method3"]}],
      "D" => []  # Separate component
    }
    
    instance = test_class.new(dependency_data)
    
    # Should identify strongly connected components
    structure = instance.analyze_graph_structure
    assert_includes structure.keys, :strongly_connected_components
    
    components = structure[:strongly_connected_components]
    assert_kind_of Array, components
    assert_equal 3, components.length  # [A,B], [C], [D]
  end
end
