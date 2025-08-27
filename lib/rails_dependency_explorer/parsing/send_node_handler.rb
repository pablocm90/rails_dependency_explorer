# frozen_string_literal: true

require_relative "base_node_handler"
require_relative "const_node_handler"

module RailsDependencyExplorer
  module Parsing
    # Handles send node processing for AST traversal.
    # Extracted from ASTVisitor to reduce complexity and improve separation of concerns.
    # Part of H2 refactoring to implement cleaner visitor pattern.
    # Updated in A3 to use BaseNodeHandler abstraction.
    class SendNodeHandler < BaseNodeHandler
      # Processes send nodes to extract method call dependencies
      # @param node [Parser::AST::Node] The send node to process
      # @param visitor [ASTVisitor] The visitor instance for recursive traversal
      # @return [Hash, Array] Method call dependencies or child visit results
      def self.handle(node, visitor)
        validate_node(node)
        process_send_node(node, visitor)
      end

      # Implementation of send node processing logic
      # @param node [Parser::AST::Node] The send node to process
      # @param visitor [ASTVisitor] The visitor instance for recursive traversal
      # @return [Hash, Array] Method call dependencies or child visit results
      def self.process_send_node(node, visitor)
        receiver = safe_child(node, 0)

        if direct_constant_call?(receiver)
          extract_direct_constant_call(receiver, node)
        elsif chained_constant_call?(receiver)
          extract_chained_constant_call(receiver)
        elsif activerecord_relationship_call?(receiver, node)
          extract_activerecord_relationship(node)
        else
          visitor.visit_children(node)
        end
      end

      # Checks if receiver is a direct constant call
      # @param receiver [Parser::AST::Node] The receiver node
      # @return [Boolean] True if direct constant call
      def self.direct_constant_call?(receiver)
        receiver&.type == :const
      end

      # Checks if receiver is a chained constant call
      # @param receiver [Parser::AST::Node] The receiver node  
      # @return [Boolean] True if chained constant call
      def self.chained_constant_call?(receiver)
        receiver&.type == :send && receiver.children[0]&.type == :const
      end

      # Extracts direct constant call dependency
      # @param receiver [Parser::AST::Node] The const receiver
      # @param node [Parser::AST::Node] The send node
      # @return [Hash] Constant to method mapping
      def self.extract_direct_constant_call(receiver, node)
        const_name = ConstNodeHandler.extract_full_constant_name(receiver)
        method_name = node.children[1].to_s
        {const_name => [method_name]}
      end

      # Extracts chained constant call dependency
      # @param receiver [Parser::AST::Node] The send receiver
      # @return [Hash] Constant to method mapping
      def self.extract_chained_constant_call(receiver)
        # Handle chained calls like GameState.current.update - only track first method
        receiver_children = receiver.children
        const_name = ConstNodeHandler.extract_full_constant_name(receiver_children[0])
        method_name = receiver_children[1].to_s
        {const_name => [method_name]}
      end

      # Checks if this is an ActiveRecord relationship call
      # @param receiver [Parser::AST::Node] The receiver node
      # @param node [Parser::AST::Node] The send node
      # @return [Boolean] True if ActiveRecord relationship call
      def self.activerecord_relationship_call?(receiver, node)
        # Check if this is a method call with nil receiver (self) and an ActiveRecord relationship method
        return false unless receiver.nil?

        method_name = child_string(node, 1)
        activerecord_relationship_method?(method_name)
      end

      # Extracts ActiveRecord relationship dependency
      # @param node [Parser::AST::Node] The send node
      # @return [Hash] ActiveRecord relationship mapping
      def self.extract_activerecord_relationship(node)
        method_name = child_string(node, 1)

        # Extract the target model from the first argument (symbol)
        first_arg = safe_child(node, 2)
        if first_arg&.type == :sym
          target_symbol = child_string(first_arg, 0)
          target_model = symbol_to_model_name(target_symbol)
          {"ActiveRecord::#{method_name}" => [target_model]}
        else
          # Fallback if we can't extract the target
          {"ActiveRecord::#{method_name}" => ["Unknown"]}
        end
      end
    end
  end
end
