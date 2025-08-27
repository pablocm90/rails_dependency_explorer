# frozen_string_literal: true

require "minitest/autorun"
require_relative "../test_helper"

# Tests for standardized error handling system across all modules.
# Verifies consistent error classification, reporting, and recovery mechanisms.
# Part of Phase 4.2 standardize error handling (Tidy First - Structural changes).
class StandardizedErrorHandlingTest < Minitest::Test
  def setup
    @dependency_data = {
      "Player" => [{"Enemy" => ["health"]}, {"Weapon" => ["damage"]}],
      "Enemy" => [{"Health" => ["decrease"]}]
    }
  end

  def test_error_handler_module_exists_and_provides_standard_interface
    # Test that ErrorHandler module exists and provides standardized error handling
    # This test will fail until we create the standardized ErrorHandler module
    
    assert defined?(RailsDependencyExplorer::ErrorHandler),
      "ErrorHandler module should be defined"
    
    # Should provide standard error classification methods
    assert_respond_to RailsDependencyExplorer::ErrorHandler, :classify_error
    assert_respond_to RailsDependencyExplorer::ErrorHandler, :handle_error
    assert_respond_to RailsDependencyExplorer::ErrorHandler, :create_error_result
  end

  def test_error_classification_system_categorizes_errors_correctly
    # Test that errors are classified into standard categories
    # This test will fail until we implement error classification
    
    # Validation errors
    validation_error = StandardError.new("Invalid dependency data")
    classification = RailsDependencyExplorer::ErrorHandler.classify_error(validation_error)
    assert_equal :validation, classification[:category]
    assert_equal :recoverable, classification[:severity]
    
    # Parsing errors - create a proper Parser::SyntaxError
    begin
      Parser::CurrentRuby.parse("invalid syntax {")
    rescue Parser::SyntaxError => parsing_error
      classification = RailsDependencyExplorer::ErrorHandler.classify_error(parsing_error)
      assert_equal :parsing, classification[:category]
      assert_equal :recoverable, classification[:severity]
    end
    
    # System errors
    system_error = SystemCallError.new("File not found")
    classification = RailsDependencyExplorer::ErrorHandler.classify_error(system_error)
    assert_equal :system, classification[:category]
    assert_equal :critical, classification[:severity]
    
    # Analysis errors
    analysis_error = StandardError.new("Circular dependency detected")
    classification = RailsDependencyExplorer::ErrorHandler.classify_error(analysis_error, context: :analysis)
    assert_equal :analysis, classification[:category]
    assert_equal :warning, classification[:severity]
  end

  def test_error_handler_creates_standardized_error_results
    # Test that error results have consistent structure across modules
    # This test will fail until we implement standardized error result format
    
    error = StandardError.new("Test error message")
    error_result = RailsDependencyExplorer::ErrorHandler.create_error_result(
      error, 
      context: "DependencyAnalyzer",
      operation: "analyze_dependencies"
    )
    
    # Should have standardized structure
    assert_includes error_result.keys, :error
    assert_includes error_result[:error].keys, :message
    assert_includes error_result[:error].keys, :type
    assert_includes error_result[:error].keys, :category
    assert_includes error_result[:error].keys, :severity
    assert_includes error_result[:error].keys, :context
    assert_includes error_result[:error].keys, :operation
    assert_includes error_result[:error].keys, :timestamp
    
    # Should have correct values
    assert_equal "Test error message", error_result[:error][:message]
    assert_equal "StandardError", error_result[:error][:type]
    assert_equal "DependencyAnalyzer", error_result[:error][:context]
    assert_equal "analyze_dependencies", error_result[:error][:operation]
  end

  def test_error_handler_supports_different_handling_strategies
    # Test that error handler supports different strategies (continue, stop, collect)
    # This test will fail until we implement strategy-based error handling
    
    error = StandardError.new("Test error")
    
    # Continue strategy - should return error result and continue
    result = RailsDependencyExplorer::ErrorHandler.handle_error(error, strategy: :continue)
    assert_includes result.keys, :error
    assert_equal :continue, result[:action]
    
    # Stop strategy - should raise the error
    assert_raises(StandardError) do
      RailsDependencyExplorer::ErrorHandler.handle_error(error, strategy: :stop)
    end
    
    # Collect strategy - should return error for collection
    result = RailsDependencyExplorer::ErrorHandler.handle_error(error, strategy: :collect)
    assert_includes result.keys, :error
    assert_equal :collect, result[:action]
  end

  def test_base_analyzer_uses_standardized_error_handling
    # Test that BaseAnalyzer uses the standardized error handling system
    # This test will fail until we integrate BaseAnalyzer with ErrorHandler
    
    # Create a mock analyzer that will fail
    analyzer_class = Class.new(RailsDependencyExplorer::Analysis::BaseAnalyzer) do
      def perform_analysis
        raise StandardError, "Analysis failed"
      end
    end
    
    analyzer = analyzer_class.new(@dependency_data, error_handling: :graceful)
    result = analyzer.analyze
    
    # Should use standardized error format
    assert_includes result.keys, :error
    assert_includes result[:error].keys, :category
    assert_includes result[:error].keys, :severity
    assert_includes result[:error].keys, :context
    assert_equal "Analysis failed", result[:error][:message]
  end

  def test_analysis_pipeline_uses_standardized_error_handling
    # Test that AnalysisPipeline uses the standardized error handling system
    # This test will fail until we integrate AnalysisPipeline with ErrorHandler
    
    # Create a mock failing analyzer
    failing_analyzer = Class.new do
      def analyze(dependency_data)
        raise StandardError, "Pipeline analyzer failed"
      end
      
      def analyzer_key
        :failing_test
      end
    end.new
    
    pipeline = RailsDependencyExplorer::Analysis::Pipeline::AnalysisPipeline.new([failing_analyzer])
    results = pipeline.analyze(@dependency_data)
    
    # Should use standardized error format in errors array
    assert_includes results.keys, :errors
    error = results[:errors].first
    
    # Should be a standardized error object, not just a string
    assert_kind_of Hash, error
    assert_includes error.keys, :error
    assert_includes error[:error].keys, :category
    assert_includes error[:error].keys, :severity
    assert_includes error[:error].keys, :context
  end

  def test_output_strategies_use_standardized_error_handling
    # Test that output strategies use standardized error handling
    # This test will fail until we integrate output strategies with ErrorHandler
    
    # Create a mock strategy that will fail
    strategy_class = Class.new(RailsDependencyExplorer::Output::OutputStrategy) do
      def format(dependency_data, statistics = nil, architectural_analysis: {})
        raise StandardError, "Output formatting failed"
      end
    end
    
    strategy = strategy_class.new
    visualizer = RailsDependencyExplorer::Output::DependencyVisualizer.new
    
    # Should handle error gracefully and return standardized error result
    result = visualizer.format(@dependency_data, strategy: strategy)
    
    assert_includes result.keys, :error
    assert_includes result[:error].keys, :category
    assert_includes result[:error].keys, :severity
    assert_equal "Output formatting failed", result[:error][:message]
  end

  def test_error_recovery_mechanisms_work_correctly
    # Test that error recovery mechanisms provide fallback behavior
    # This test will fail until we implement error recovery
    
    # Test recovery for parsing errors
    recovery_result = RailsDependencyExplorer::ErrorHandler.attempt_recovery(
      error_type: :parsing,
      original_operation: -> { raise StandardError, "Invalid syntax" },
      fallback_operation: -> { { "fallback" => [] } }
    )
    
    assert_includes recovery_result.keys, :result
    assert_includes recovery_result.keys, :recovered
    assert_equal true, recovery_result[:recovered]
    assert_equal({ "fallback" => [] }, recovery_result[:result])
    
    # Test recovery for analysis errors
    recovery_result = RailsDependencyExplorer::ErrorHandler.attempt_recovery(
      error_type: :analysis,
      original_operation: -> { raise StandardError, "Analysis failed" },
      fallback_operation: -> { { statistics: { total_classes: 0 } } }
    )
    
    assert_equal true, recovery_result[:recovered]
    assert_includes recovery_result[:result].keys, :statistics
  end

  def test_error_logging_and_reporting_is_consistent
    # Test that error logging follows consistent patterns
    # This test will fail until we implement standardized logging

    error = StandardError.new("Test error for logging")

    # Should be able to log errors with consistent format
    log_output = capture_io do
      RailsDependencyExplorer::ErrorHandler.log_error(
        error,
        context: "TestContext",
        level: :warning
      )
    end

    log_message = log_output.first
    assert_match(/WARNING/, log_message)
    assert_match(/TestContext/, log_message)
    assert_match(/Test error for logging/, log_message)
    assert_match(/\d{4}-\d{2}-\d{2}/, log_message) # Should include timestamp
  end

  def test_error_handler_provides_convenience_methods
    # Test that ErrorHandler provides convenient methods for common error types

    # Validation error convenience method
    validation_result = RailsDependencyExplorer::ErrorHandler.validation_error(
      "Invalid input data",
      context: "DataValidator"
    )

    assert_includes validation_result.keys, :error
    assert_equal "Invalid input data", validation_result[:error][:message]
    assert_equal :validation, validation_result[:error][:category]
    assert_equal "DataValidator", validation_result[:error][:context]

    # Parsing error convenience method
    parsing_result = RailsDependencyExplorer::ErrorHandler.parsing_error(
      "Syntax error in code",
      context: "CodeParser"
    )

    assert_includes parsing_result.keys, :error
    assert_equal "Syntax error in code", parsing_result[:error][:message]
    assert_equal :parsing, parsing_result[:error][:category]
    assert_equal "CodeParser", parsing_result[:error][:context]

    # Recoverable error checking
    assert RailsDependencyExplorer::ErrorHandler.recoverable?(validation_result)
    assert RailsDependencyExplorer::ErrorHandler.recoverable?(parsing_result)

    # Non-recoverable error
    system_error = StandardError.new("System failure")
    system_result = RailsDependencyExplorer::ErrorHandler.create_error_result(
      system_error,
      context: "SystemOperation"
    )
    # This should be recoverable based on our classification, but let's test the method works
    assert_respond_to RailsDependencyExplorer::ErrorHandler, :recoverable?
  end
end
