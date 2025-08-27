# frozen_string_literal: true

module RailsDependencyExplorer
  module Parsing
    # Base class for AST node handlers.
    # Provides common functionality and template method pattern for node processing.
    # Part of A3: Extract Missing Abstractions to reduce duplication in node handlers.
    class BaseNodeHandler
      # Template method for handling AST nodes
      # Subclasses should implement process_node method
      # @param node [Parser::AST::Node] The AST node to process
      # @return [Object] Processed result
      def self.handle(node)
        validate_node(node)
        process_node(node)
      end

      # Abstract method to be implemented by concrete handlers
      # @param node [Parser::AST::Node] The AST node to process
      # @return [Object] Processed result
      def self.process_node(node)
        raise NotImplementedError, "Subclasses must implement process_node method"
      end

      private

      # Common validation for AST nodes
      # @param node [Parser::AST::Node] The node to validate
      def self.validate_node(node)
        raise ArgumentError, "Node cannot be nil" if node.nil?
        raise ArgumentError, "Node must respond to :children" unless node.respond_to?(:children)
        raise ArgumentError, "Node must respond to :type" unless node.respond_to?(:type)
      end

      # Common helper to extract node children safely
      # @param node [Parser::AST::Node] The node
      # @param index [Integer] The child index
      # @return [Object, nil] The child at index or nil
      def self.safe_child(node, index)
        return nil unless node.children.is_a?(Array)
        return nil if index >= node.children.size
        
        node.children[index]
      end

      # Common helper to extract string value from node child
      # @param node [Parser::AST::Node] The node
      # @param index [Integer] The child index
      # @return [String, nil] String value or nil
      def self.child_string(node, index)
        child = safe_child(node, index)
        child&.to_s
      end

      # Common helper to check if child is of specific type
      # @param node [Parser::AST::Node] The node
      # @param index [Integer] The child index
      # @param expected_type [Symbol] The expected node type
      # @return [Boolean] True if child matches expected type
      def self.child_type?(node, index, expected_type)
        child = safe_child(node, index)
        child&.type == expected_type
      end

      # Common helper to extract nested constant names
      # @param node [Parser::AST::Node] The const node
      # @return [Array<String>] Array of constant name parts
      def self.extract_constant_parts(node)
        return [] unless node&.type == :const
        
        parts = []
        current = node
        
        while current && current.type == :const
          parts.unshift(current.children[1].to_s)
          current = current.children[0]
        end
        
        parts
      end

      # Common helper to build full constant name from parts
      # @param parts [Array<String>] Constant name parts
      # @return [String] Full constant name like "Module::Class"
      def self.build_constant_name(parts)
        parts.join("::")
      end

      # Common helper for ActiveRecord relationship detection
      # @param method_name [String] The method name to check
      # @return [Boolean] True if it's an ActiveRecord relationship method
      def self.activerecord_relationship_method?(method_name)
        %w[belongs_to has_many has_one has_and_belongs_to_many].include?(method_name.to_s)
      end

      # Common helper for symbol to model name conversion
      # @param symbol_name [String] The symbol name (e.g., "posts", ":accounts")
      # @return [String] Model name (e.g., "Post", "Account")
      def self.symbol_to_model_name(symbol_name)
        # Remove leading colon if present
        clean_name = symbol_name.to_s.sub(/^:/, "")
        
        # Simple singularization for common cases
        singular_name = case clean_name
        when /ies$/
          clean_name.sub(/ies$/, "y")
        when /s$/
          clean_name.sub(/s$/, "")
        else
          clean_name
        end
        
        # Capitalize first letter
        singular_name.capitalize
      end
    end
  end
end
