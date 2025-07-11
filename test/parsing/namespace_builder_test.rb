# frozen_string_literal: true

require "test_helper"

class NamespaceBuilderTest < Minitest::Test
  def test_initialize_with_empty_namespace_stack
    builder = RailsDependencyExplorer::Parsing::NamespaceBuilder.new
    
    assert_equal [], builder.namespace_stack
  end

  def test_initialize_with_provided_namespace_stack
    stack = ["App", "Models"]
    builder = RailsDependencyExplorer::Parsing::NamespaceBuilder.new(stack)
    
    assert_equal ["App", "Models"], builder.namespace_stack
  end

  def test_build_full_name_with_empty_stack
    builder = RailsDependencyExplorer::Parsing::NamespaceBuilder.new
    
    full_name = builder.build_full_name("User")
    assert_equal "User", full_name
  end

  def test_build_full_name_with_single_namespace
    builder = RailsDependencyExplorer::Parsing::NamespaceBuilder.new(["App"])
    
    full_name = builder.build_full_name("User")
    assert_equal "App::User", full_name
  end

  def test_build_full_name_with_multiple_namespaces
    builder = RailsDependencyExplorer::Parsing::NamespaceBuilder.new(["App", "Models"])
    
    full_name = builder.build_full_name("User")
    assert_equal "App::Models::User", full_name
  end

  def test_build_full_name_with_empty_immediate_name
    builder = RailsDependencyExplorer::Parsing::NamespaceBuilder.new(["App", "Models"])
    
    full_name = builder.build_full_name("")
    assert_equal "App::Models::", full_name
  end

  def test_push_namespace_returns_new_builder
    original_builder = RailsDependencyExplorer::Parsing::NamespaceBuilder.new(["App"])
    
    new_builder = original_builder.push_namespace("Models")
    
    # Should return a new instance
    refute_same original_builder, new_builder
    
    # Original should be unchanged
    assert_equal ["App"], original_builder.namespace_stack
    
    # New should have updated stack
    assert_equal ["App", "Models"], new_builder.namespace_stack
  end

  def test_push_namespace_with_empty_string
    builder = RailsDependencyExplorer::Parsing::NamespaceBuilder.new(["App"])
    
    new_builder = builder.push_namespace("")
    
    assert_equal ["App", ""], new_builder.namespace_stack
  end

  def test_push_multiple_namespaces_chaining
    builder = RailsDependencyExplorer::Parsing::NamespaceBuilder.new
    
    final_builder = builder
      .push_namespace("App")
      .push_namespace("Models")
      .push_namespace("Concerns")
    
    assert_equal ["App", "Models", "Concerns"], final_builder.namespace_stack
  end

  def test_immutability_of_namespace_stack
    original_stack = ["App", "Models"]
    builder = RailsDependencyExplorer::Parsing::NamespaceBuilder.new(original_stack)
    
    # Modify the original stack
    original_stack << "User"
    
    # Builder's stack should be unaffected
    assert_equal ["App", "Models"], builder.namespace_stack
  end

  def test_build_class_info_structure
    builder = RailsDependencyExplorer::Parsing::NamespaceBuilder.new(["App", "Models"])
    
    # Mock AST node
    mock_node = Minitest::Mock.new
    mock_node.expect(:type, :class)
    
    class_info = builder.build_class_info(mock_node, "User")
    
    expected_info = {
      node: mock_node,
      full_name: "App::Models::User",
      namespace_stack: ["App", "Models"],
      type: :class
    }
    
    assert_equal expected_info, class_info
    mock_node.verify
  end

  def test_build_class_info_with_module
    builder = RailsDependencyExplorer::Parsing::NamespaceBuilder.new(["App"])
    
    # Mock AST node
    mock_node = Minitest::Mock.new
    mock_node.expect(:type, :module)
    
    class_info = builder.build_class_info(mock_node, "Services")
    
    expected_info = {
      node: mock_node,
      full_name: "App::Services",
      namespace_stack: ["App"],
      type: :module
    }
    
    assert_equal expected_info, class_info
    mock_node.verify
  end

  def test_build_class_info_preserves_original_namespace_stack
    original_stack = ["App", "Models"]
    builder = RailsDependencyExplorer::Parsing::NamespaceBuilder.new(original_stack)
    
    mock_node = Minitest::Mock.new
    mock_node.expect(:type, :class)
    
    class_info = builder.build_class_info(mock_node, "User")
    
    # Modify the returned namespace_stack
    class_info[:namespace_stack] << "Modified"
    
    # Original builder's stack should be unchanged
    assert_equal ["App", "Models"], builder.namespace_stack
    mock_node.verify
  end
end
