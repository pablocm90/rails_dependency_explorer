# frozen_string_literal: true

require "test_helper"

# Tests for utility class organization and proper module structure.
# Ensures utility classes are properly organized under Utils module
# for better discoverability and maintainability.
# Part of Phase 1.3 architectural refactoring (Tidy First - Structural changes only).
class UtilityOrganizationTest < Minitest::Test
  def test_utils_module_exists
    # Test that Utils module exists as the main utility namespace
    assert defined?(RailsDependencyExplorer::Utils),
      "Utils module should be defined as main utility namespace"
  end

  def test_graph_utilities_module_exists
    # Test that GraphUtils module exists for graph-related utilities
    assert defined?(RailsDependencyExplorer::Utils::GraphUtils),
      "Utils::GraphUtils module should be defined for graph utilities"
    
    # Test that GraphBuilder is accessible through Utils
    assert defined?(RailsDependencyExplorer::Utils::GraphUtils::GraphBuilder),
      "GraphBuilder should be accessible through Utils::GraphUtils"
  end

  def test_ast_utilities_module_exists
    # Test that ASTUtils module exists for AST-related utilities
    assert defined?(RailsDependencyExplorer::Utils::ASTUtils),
      "Utils::ASTUtils module should be defined for AST utilities"
    
    # Test that AST utilities are accessible through Utils
    assert defined?(RailsDependencyExplorer::Utils::ASTUtils::ASTBuilder),
      "ASTBuilder should be accessible through Utils::ASTUtils"
    
    assert defined?(RailsDependencyExplorer::Utils::ASTUtils::ASTNodeUtils),
      "ASTNodeUtils should be accessible through Utils::ASTUtils"
  end

  def test_parsing_utilities_module_exists
    # Test that ParsingUtils module exists for parsing-related utilities
    assert defined?(RailsDependencyExplorer::Utils::ParsingUtils),
      "Utils::ParsingUtils module should be defined for parsing utilities"
    
    # Test that parsing utilities are accessible through Utils
    assert defined?(RailsDependencyExplorer::Utils::ParsingUtils::DependencyParserUtils),
      "DependencyParserUtils should be accessible through Utils::ParsingUtils"
    
    assert defined?(RailsDependencyExplorer::Utils::ParsingUtils::NamespaceBuilder),
      "NamespaceBuilder should be accessible through Utils::ParsingUtils"
    
    assert defined?(RailsDependencyExplorer::Utils::ParsingUtils::ContentFilter),
      "ContentFilter should be accessible through Utils::ParsingUtils"
  end

  def test_formatting_utilities_module_exists
    # Test that FormattingUtils module exists for formatting-related utilities
    assert defined?(RailsDependencyExplorer::Utils::FormattingUtils),
      "Utils::FormattingUtils module should be defined for formatting utilities"
    
    # Test that formatting utilities are accessible through Utils
    assert defined?(RailsDependencyExplorer::Utils::FormattingUtils::ArchitecturalCycleFormatter),
      "ArchitecturalCycleFormatter should be accessible through Utils::FormattingUtils"
  end

  def test_state_utilities_module_exists
    # Test that StateUtils module exists for state management utilities
    assert defined?(RailsDependencyExplorer::Utils::StateUtils),
      "Utils::StateUtils module should be defined for state utilities"
    
    # Test that state utilities are accessible through Utils
    assert defined?(RailsDependencyExplorer::Utils::StateUtils::DfsState),
      "DfsState should be accessible through Utils::StateUtils"
    
    assert defined?(RailsDependencyExplorer::Utils::StateUtils::DepthCalculationState),
      "DepthCalculationState should be accessible through Utils::StateUtils"
  end

  def test_filter_utilities_module_exists
    # Test that FilterUtils module exists for filtering utilities
    assert defined?(RailsDependencyExplorer::Utils::FilterUtils),
      "Utils::FilterUtils module should be defined for filter utilities"
    
    # Test that filter utilities are accessible through Utils
    assert defined?(RailsDependencyExplorer::Utils::FilterUtils::CrossNamespaceCycleFilter),
      "CrossNamespaceCycleFilter should be accessible through Utils::FilterUtils"
  end

  def test_backward_compatibility_maintained
    # Test that original class locations still work for backward compatibility
    
    # Graph utilities
    assert defined?(RailsDependencyExplorer::Analysis::GraphBuilder),
      "Original GraphBuilder location should still work for backward compatibility"
    
    # AST utilities
    assert defined?(RailsDependencyExplorer::Parsing::ASTBuilder),
      "Original ASTBuilder location should still work for backward compatibility"
    
    assert defined?(RailsDependencyExplorer::Parsing::ASTNodeUtils),
      "Original ASTNodeUtils location should still work for backward compatibility"
    
    # Parsing utilities
    assert defined?(RailsDependencyExplorer::Parsing::DependencyParserUtils),
      "Original DependencyParserUtils location should still work for backward compatibility"
    
    # State utilities
    assert defined?(RailsDependencyExplorer::Analysis::DfsState),
      "Original DfsState location should still work for backward compatibility"
    
    assert defined?(RailsDependencyExplorer::Analysis::DepthCalculationState),
      "Original DepthCalculationState location should still work for backward compatibility"
  end

  def test_utility_classes_have_consistent_interface
    # Test that utility classes follow consistent patterns
    
    # GraphBuilder should have class methods
    assert_respond_to RailsDependencyExplorer::Utils::GraphUtils::GraphBuilder, :build_adjacency_list,
      "GraphBuilder should have build_adjacency_list class method"
    
    # ASTBuilder should have class methods
    assert_respond_to RailsDependencyExplorer::Utils::ASTUtils::ASTBuilder, :build_ast,
      "ASTBuilder should have build_ast class method"
    
    # ASTNodeUtils should have class methods
    assert_respond_to RailsDependencyExplorer::Utils::ASTUtils::ASTNodeUtils, :extract_class_name,
      "ASTNodeUtils should have extract_class_name class method"
  end

  def test_utils_module_structure_is_logical
    # Test that the Utils module structure makes logical sense
    
    # Utils should be a module, not a class
    assert RailsDependencyExplorer::Utils.is_a?(Module),
      "Utils should be a module"
    
    # Sub-modules should also be modules
    assert RailsDependencyExplorer::Utils::GraphUtils.is_a?(Module),
      "GraphUtils should be a module"
    
    assert RailsDependencyExplorer::Utils::ASTUtils.is_a?(Module),
      "ASTUtils should be a module"
    
    assert RailsDependencyExplorer::Utils::ParsingUtils.is_a?(Module),
      "ParsingUtils should be a module"
  end
end
