# frozen_string_literal: true

require_relative "../analysis/configuration/dependency_collection"

module RailsDependencyExplorer
  module Parsing
    # Accumulates dependency information during AST traversal.
    # Collects method calls, constant references, and other dependency data
    # from AST visitors and organizes them for further analysis.
    class DependencyAccumulator
      attr_reader :collection

      def initialize
        @collection = Analysis::Configuration::DependencyCollection.new
      end

      def record_method_call(constant_name, method_name)
        @collection.add_method_call(constant_name, method_name)
      end

      def record_constant_access(constant_name, accessed_constant)
        @collection.add_constant_access(constant_name, accessed_constant)
      end

      def record_hash_dependency(hash_dependency)
        @collection.merge_hash_dependency(hash_dependency)
      end
    end
  end
end
