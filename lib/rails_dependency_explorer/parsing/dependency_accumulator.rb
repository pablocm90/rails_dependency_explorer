# frozen_string_literal: true

require_relative "../analysis/dependency_collection"

module RailsDependencyExplorer
  module Parsing
    class DependencyAccumulator
    attr_reader :collection

    def initialize
      @collection = Analysis::DependencyCollection.new
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
