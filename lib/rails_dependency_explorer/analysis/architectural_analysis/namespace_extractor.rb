# frozen_string_literal: true

module RailsDependencyExplorer
  module Analysis
    module ArchitecturalAnalysis
    # Extracts namespace information from Ruby class names.
    # Handles both namespaced classes (App::Models::User) and root-level classes (User).
    class NamespaceExtractor
      def self.extract_namespace(class_name)
        parts = class_name.split("::")
        return "" if parts.length == 1 # Root namespace
        parts[0..-2].join("::")
      end

      def self.extract_namespaces_from_cycle(cycle)
        # Remove the duplicate last element (cycle completion)
        unique_classes = cycle[0..-2]
        unique_classes.map { |class_name| extract_namespace(class_name) }.uniq
      end
    end
  end
end
end
