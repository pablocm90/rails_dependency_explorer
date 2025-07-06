# frozen_string_literal: true

module RailsDependencyExplorer
  module Analysis
    class DependencyCollection
    def initialize
      @dependencies = {}
    end

    def add_method_call(constant_name, method_name)
      @dependencies[constant_name] ||= []
      @dependencies[constant_name] << method_name unless @dependencies[constant_name].include?(method_name)
    end

    def add_constant_access(constant_name, accessed_constant)
      add_method_call(constant_name, accessed_constant)
    end

    def to_grouped_array
      @dependencies.map { |const_name, methods| {const_name => methods} }
    end

    def merge_hash_dependency(hash_dep)
      hash_dep.each do |const_name, methods|
        methods.each { |method| add_method_call(const_name, method) }
      end
    end
    end
  end
end
