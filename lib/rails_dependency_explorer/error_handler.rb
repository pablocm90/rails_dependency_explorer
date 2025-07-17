# frozen_string_literal: true

require "time"

module RailsDependencyExplorer
  # Standardized error handling system for consistent error classification,
  # reporting, and recovery across all modules.
  # Part of Phase 4.2 standardize error handling (Tidy First - Structural changes).
  module ErrorHandler
    # Error categories for classification
    ERROR_CATEGORIES = {
      validation: :validation,
      parsing: :parsing,
      analysis: :analysis,
      output: :output,
      system: :system,
      network: :network,
      configuration: :configuration
    }.freeze

    # Error severity levels
    ERROR_SEVERITIES = {
      info: :info,
      warning: :warning,
      recoverable: :recoverable,
      critical: :critical,
      fatal: :fatal
    }.freeze

    # Classify an error into category and severity
    # @param error [Exception] The error to classify
    # @param context [Symbol] Optional context hint for classification
    # @return [Hash] Classification with :category and :severity
    def self.classify_error(error, context: nil)
      category = determine_category(error, context)
      severity = determine_severity(error, category)
      
      {
        category: category,
        severity: severity
      }
    end

    # Handle an error according to the specified strategy
    # @param error [Exception] The error to handle
    # @param strategy [Symbol] Handling strategy (:continue, :stop, :collect)
    # @param context [String] Context where error occurred
    # @param operation [String] Operation that failed
    # @return [Hash] Error result or raises error based on strategy
    def self.handle_error(error, strategy: :continue, context: nil, operation: nil)
      case strategy
      when :stop
        raise error
      when :continue, :collect
        error_result = create_error_result(error, context: context, operation: operation)
        error_result[:action] = strategy
        error_result
      else
        # Default to continue
        error_result = create_error_result(error, context: context, operation: operation)
        error_result[:action] = :continue
        error_result
      end
    end

    # Create a standardized error result structure
    # @param error [Exception] The error to format
    # @param context [String] Context where error occurred
    # @param operation [String] Operation that failed
    # @return [Hash] Standardized error result
    def self.create_error_result(error, context: nil, operation: nil)
      classification = classify_error(error, context: context&.to_sym)
      
      {
        error: {
          message: error.message,
          type: error.class.name,
          category: classification[:category],
          severity: classification[:severity],
          context: context,
          operation: operation,
          timestamp: Time.now.iso8601,
          backtrace: error.backtrace&.first(5)
        }
      }
    end

    # Attempt error recovery with fallback operation
    # @param error_type [Symbol] Type of error for recovery strategy
    # @param original_operation [Proc] The operation that failed
    # @param fallback_operation [Proc] Fallback operation to try
    # @return [Hash] Recovery result with :result and :recovered keys
    def self.attempt_recovery(error_type:, original_operation:, fallback_operation:)
      begin
        result = original_operation.call
        { result: result, recovered: false }
      rescue StandardError => e
        log_error(e, context: "Recovery", level: :warning)
        fallback_result = fallback_operation.call
        { result: fallback_result, recovered: true, original_error: e }
      end
    end

    # Log an error with consistent formatting
    # @param error [Exception] The error to log
    # @param context [String] Context where error occurred
    # @param level [Symbol] Log level (:info, :warning, :error)
    def self.log_error(error, context: nil, level: :error)
      timestamp = Time.now.strftime("%Y-%m-%d %H:%M:%S")
      level_str = level.to_s.upcase
      context_str = context ? "[#{context}] " : ""

      puts "#{timestamp} #{level_str}: #{context_str}#{error.message}"
    end

    # Convenience method for handling validation errors
    # @param message [String] Validation error message
    # @param context [String] Context where validation failed
    # @return [Hash] Standardized error result
    def self.validation_error(message, context: nil)
      error = ArgumentError.new(message)
      create_error_result(error, context: context, operation: "validation")
    end

    # Convenience method for handling parsing errors
    # @param message [String] Parsing error message
    # @param context [String] Context where parsing failed
    # @return [Hash] Standardized error result
    def self.parsing_error(message, context: nil)
      error = StandardError.new(message)
      create_error_result(error, context: context, operation: "parsing")
    end

    # Check if an error result indicates a recoverable error
    # @param error_result [Hash] Error result from create_error_result
    # @return [Boolean] true if error is recoverable
    def self.recoverable?(error_result)
      return false unless error_result.is_a?(Hash) && error_result.key?(:error)

      severity = error_result[:error][:severity]
      [:info, :warning, :recoverable].include?(severity)
    end

    private

    # Determine error category based on error type and context
    def self.determine_category(error, context)
      # Context-based classification
      return context if context && ERROR_CATEGORIES.key?(context)
      
      # Type-based classification
      case error
      when Parser::SyntaxError
        :parsing
      when SystemCallError, Errno::ENOENT, Errno::EACCES
        :system
      when ArgumentError, TypeError
        :validation
      when StandardError
        # Check error message for hints
        message = error.message.downcase
        return :parsing if message.include?("syntax") || message.include?("parse")
        return :validation if message.include?("invalid") || message.include?("missing")
        return :analysis if message.include?("circular") || message.include?("dependency")
        return :output if message.include?("format") || message.include?("render")
        
        :analysis # Default for StandardError
      else
        :system
      end
    end

    # Determine error severity based on error type and category
    def self.determine_severity(error, category)
      case category
      when :parsing, :validation
        :recoverable
      when :analysis
        :warning
      when :output
        :recoverable
      when :system
        :critical
      when :configuration
        :critical
      else
        case error
        when SystemCallError
          :critical
        when ArgumentError, TypeError
          :recoverable
        else
          :warning
        end
      end
    end
  end
end
