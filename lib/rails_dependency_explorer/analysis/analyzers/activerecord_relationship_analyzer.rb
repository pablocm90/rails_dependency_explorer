# frozen_string_literal: true

require_relative "../base_analyzer"
require_relative "../interfaces/component_analyzer_interface"

module RailsDependencyExplorer
  module Analysis
    module Analyzers
      # Analyzes ActiveRecord relationships and associations in Rails models.
    # Detects belongs_to, has_many, has_one, and has_and_belongs_to_many relationships
    # to provide insights into model associations and database relationships.
    class ActiveRecordRelationshipAnalyzer < BaseAnalyzer
      include Interfaces::ComponentAnalyzerInterface

      # Mapping of ActiveRecord relationship constants to relationship types
      RELATIONSHIP_TYPE_MAPPING = {
        "ActiveRecord::belongs_to" => :belongs_to,
        "ActiveRecord::has_many" => :has_many,
        "ActiveRecord::has_one" => :has_one,
        "ActiveRecord::has_and_belongs_to_many" => :has_and_belongs_to_many
      }.freeze

      # Implementation of BaseAnalyzer template method
      def perform_analysis
        analyze_relationships
      end

      # Pipeline integration - specify the key for pipeline results
      def analyzer_key
        :activerecord_relationships
      end

      def analyze_relationships
        relationships = {}

        @dependency_data.each do |class_name, dependencies|
          relationships[class_name] = extract_relationships_for_class(dependencies)
        end

        relationships
      end

      private

      def extract_relationships_for_class(dependencies)
        class_relationships = {
          belongs_to: [],
          has_many: [],
          has_one: [],
          has_and_belongs_to_many: []
        }

        dependencies.each do |dep|
          next unless dep.is_a?(Hash)

          dep.each do |constant_name, target_models|
            # Look for ActiveRecord relationship constants
            relationship_type = extract_relationship_type(constant_name)
            if relationship_type
              target_models.each do |target_model|
                class_relationships[relationship_type] << target_model
              end
            end
          end
        end

        class_relationships
      end

      def extract_relationship_type(constant_name)
        # Extract relationship type from "ActiveRecord::belongs_to" format using mapping
        RELATIONSHIP_TYPE_MAPPING[constant_name]
      end
    end
    end
  end
end
