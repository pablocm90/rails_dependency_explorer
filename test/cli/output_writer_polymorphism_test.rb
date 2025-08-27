# frozen_string_literal: true

require "test_helper"

# Test to demonstrate replacing complex conditionals with polymorphism in OutputWriter
# Shows the current case statement logic and verifies the polymorphic replacement
class OutputWriterPolymorphismTest < Minitest::Test
  def setup
    @writer = RailsDependencyExplorer::CLI::OutputWriter.new
    @mock_result = create_mock_result
  end

  def test_current_format_output_uses_case_statement
    # RED: This test demonstrates the current case statement logic in format_output
    # The method currently uses a case statement to switch between formats
    
    # Test each format type
    dot_output = @writer.format_output(@mock_result, "dot")
    assert_includes dot_output, "digraph dependencies"
    
    json_output = @writer.format_output(@mock_result, "json")
    assert_includes json_output, "dependencies"
    
    html_output = @writer.format_output(@mock_result, "html")
    assert_includes html_output, "<!DOCTYPE html>"
    
    csv_output = @writer.format_output(@mock_result, "csv")
    assert_includes csv_output, "Source,Target"
    
    console_output = @writer.format_output(@mock_result, "console")
    assert_includes console_output, "Dependencies found"
  end

  def test_format_output_handles_unknown_format_with_default
    # The current implementation defaults to console format for unknown formats
    unknown_output = @writer.format_output(@mock_result, "unknown")
    assert_includes unknown_output, "Dependencies found"
  end

  def test_format_output_supports_options_for_console
    # Test that console format supports additional options
    options = {
      include_stats: true,
      include_circular: true,
      include_depth: true
    }
    
    console_output = @writer.format_output(@mock_result, "console", options)
    assert_includes console_output, "Dependencies found"
    assert_includes console_output, "Statistics:"
    assert_includes console_output, "Circular Dependencies:"
    assert_includes console_output, "Dependency Depth:"
  end

  def test_format_output_case_statement_violates_open_closed_principle
    # RED: This test demonstrates that the current case statement violates OCP
    # Adding a new format requires modifying the OutputWriter class
    
    # The current format_output method has a case statement:
    # case format
    # when "dot" then result.to_dot
    # when "json" then result.to_json
    # when "html" then result.to_html
    # when "csv" then result.to_csv
    # else format_console_output(result, options)
    # end
    
    # This violates the Open/Closed Principle because:
    # 1. Adding new formats requires modifying existing code
    # 2. The method has multiple responsibilities (format detection + delegation)
    # 3. Format-specific logic is mixed with coordination logic
    
    # Verify the current behavior works but acknowledge the design issue
    result = @writer.format_output(@mock_result, "json")
    assert_instance_of String, result
    
    # The case statement makes this method responsible for:
    # 1. Format type detection
    # 2. Method selection
    # 3. Result delegation
    # 4. Default handling
    # This should be replaced with polymorphic dispatch
  end

  def test_output_writer_should_delegate_to_format_strategies
    # GREEN: This test shows how OutputWriter should delegate to format strategies
    # instead of using case statements
    
    # The OutputWriter should use a strategy pattern where:
    # 1. Each format has its own strategy class
    # 2. The OutputWriter delegates to the appropriate strategy
    # 3. New formats can be added without modifying existing code
    
    # For now, verify current behavior works
    formats = ["dot", "json", "html", "csv", "console"]
    
    formats.each do |format|
      result = @writer.format_output(@mock_result, format)
      assert_instance_of String, result
      refute_empty result
    end
  end

  def test_console_format_handles_multiple_options_via_strategy
    # Test that console format handles options through the strategy pattern
    options = {
      include_stats: true,
      include_circular: false,
      include_depth: true
    }

    # Use the public format_output method with console format
    console_output = @writer.format_output(@mock_result, "console", options)

    assert_includes console_output, "Dependencies found"
    assert_includes console_output, "Statistics:"
    refute_includes console_output, "Circular Dependencies:"
    assert_includes console_output, "Dependency Depth:"
  end

  def test_static_formatting_methods_work_independently
    # Test that static formatting methods work independently
    stats = { total_classes: 5, total_dependencies: 10, most_used_dependency: "User" }
    cycles = [["A", "B", "A"], ["C", "D", "C"]]
    depths = { "User" => 1, "Post" => 2 }
    
    stats_output = RailsDependencyExplorer::CLI::OutputWriter.format_statistics(stats)
    assert_includes stats_output, "Total Classes: 5"
    assert_includes stats_output, "Most Used Dependency: User"
    
    cycles_output = RailsDependencyExplorer::CLI::OutputWriter.format_circular_dependencies(cycles)
    assert_includes cycles_output, "A -> B -> A"
    assert_includes cycles_output, "C -> D -> C"
    
    depths_output = RailsDependencyExplorer::CLI::OutputWriter.format_dependency_depth(depths)
    assert_includes depths_output, "User: 1"
    assert_includes depths_output, "Post: 2"
  end

  private

  def create_mock_result
    # Create a mock result object that responds to all format methods
    mock_result = Object.new
    
    # Define singleton methods for each format
    def mock_result.to_dot
      "digraph dependencies { \"A\" -> \"B\"; }"
    end
    
    def mock_result.to_json
      '{"dependencies": {"A": ["B"]}}'
    end
    
    def mock_result.to_html
      "<!DOCTYPE html><html><body>Dependencies Report</body></html>"
    end
    
    def mock_result.to_csv
      "Source,Target,Methods\nA,B,method1"
    end
    
    def mock_result.to_console
      "Dependencies found:\n  A -> B"
    end
    
    def mock_result.statistics
      { total_classes: 2, total_dependencies: 1, most_used_dependency: "B" }
    end
    
    def mock_result.circular_dependencies
      [["A", "B", "A"]]
    end
    
    def mock_result.dependency_depth
      { "A" => 1, "B" => 2 }
    end
    
    mock_result
  end
end
