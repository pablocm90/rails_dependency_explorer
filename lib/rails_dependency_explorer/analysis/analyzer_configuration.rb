# frozen_string_literal: true

require 'set'
require_relative 'analyzer_discovery'

module RailsDependencyExplorer
  module Analysis
    # Configuration system for enabling/disabling analyzers.
    # Provides flexible configuration options for the pluggable analyzer system.
    # Part of Phase 3.2.2 configuration system implementation.
    class AnalyzerConfiguration
      def initialize(discovery: nil)
        @discovery = discovery || AnalyzerDiscovery.new
        @enabled_analyzers = Set.new
        @disabled_analyzers = Set.new
        @enabled_categories = Set.new
        @disabled_categories = Set.new
        
        # Enable all analyzers by default
        reset
      end

      # Get list of enabled analyzer keys
      def enabled_analyzers
        available_analyzers = @discovery.discover_analyzers
        enabled_set = calculate_enabled_analyzers(available_analyzers)
        enabled_set.to_a
      end

      # Check if specific analyzer is enabled
      def analyzer_enabled?(analyzer_key)
        enabled_analyzers.include?(analyzer_key)
      end

      # Get enabled analyzer classes
      def enabled_analyzer_classes
        available_analyzers = @discovery.discover_analyzers
        enabled_keys = enabled_analyzers

        enabled_keys.each_with_object({}) do |key, result|
          result[key] = available_analyzers[key] if available_analyzers[key]
        end
      end

      # Enable specific analyzer
      def enable(analyzer_key)
        # Only enable if the analyzer actually exists
        available_analyzers = @discovery.discover_analyzers
        if available_analyzers.key?(analyzer_key)
          @enabled_analyzers.add(analyzer_key)
          @disabled_analyzers.delete(analyzer_key)
        end
        # Silently ignore unknown analyzers
      end

      # Disable specific analyzer
      def disable(analyzer_key)
        # Only disable if the analyzer actually exists
        available_analyzers = @discovery.discover_analyzers
        if available_analyzers.key?(analyzer_key)
          @disabled_analyzers.add(analyzer_key)
          @enabled_analyzers.delete(analyzer_key)
        end
        # Silently ignore unknown analyzers
      end

      # Enable all analyzers
      def enable_all
        @enabled_analyzers.clear
        @disabled_analyzers.clear
        @enabled_categories.clear
        @disabled_categories.clear
      end

      # Disable all analyzers
      def disable_all
        available_analyzers = @discovery.discover_analyzers
        @disabled_analyzers = Set.new(available_analyzers.keys)
        @enabled_analyzers.clear
      end

      # Enable analyzers by category
      def enable_category(category)
        # Only enable if the category actually has analyzers
        analyzers_in_category = get_analyzers_in_category(category)
        if analyzers_in_category.any?
          @enabled_categories.add(category)
          @disabled_categories.delete(category)

          # Remove analyzers in this category from disabled list
          @disabled_analyzers -= analyzers_in_category
        end
        # Silently ignore unknown categories
      end

      # Disable analyzers by category
      def disable_category(category)
        # Only disable if the category actually has analyzers
        analyzers_in_category = get_analyzers_in_category(category)
        if analyzers_in_category.any?
          @disabled_categories.add(category)
          @enabled_categories.delete(category)

          # Add analyzers in this category to disabled list
          @disabled_analyzers |= analyzers_in_category
        end
        # Silently ignore unknown categories
      end

      # Configure from hash
      def configure(config_hash)
        # Handle enabled/disabled analyzers
        if config_hash[:enabled]
          disable_all
          Array(config_hash[:enabled]).each { |analyzer| enable(analyzer) }
        end
        
        if config_hash[:disabled]
          Array(config_hash[:disabled]).each { |analyzer| disable(analyzer) }
        end
        
        # Handle enabled/disabled categories
        if config_hash[:enabled_categories]
          Array(config_hash[:enabled_categories]).each { |category| enable_category(category) }
        end
        
        if config_hash[:disabled_categories]
          Array(config_hash[:disabled_categories]).each { |category| disable_category(category) }
        end
      end

      # Reset to default configuration (all enabled)
      def reset
        enable_all
      end

      private

      # Calculate the final set of enabled analyzers
      def calculate_enabled_analyzers(available_analyzers)
        # Start with all available analyzers
        enabled = Set.new(available_analyzers.keys)

        # Apply category-based filtering first
        enabled = apply_category_filters(enabled)

        # Apply specific analyzer filters
        enabled = apply_analyzer_filters(enabled)

        enabled
      end

      # Apply category-based filters
      def apply_category_filters(enabled)
        return enabled if no_category_filters?

        enabled = apply_enabled_category_filters(enabled) if @enabled_categories.any?
        enabled = apply_disabled_category_filters(enabled) if @disabled_categories.any?

        enabled
      end

      # Check if no category filters are active
      def no_category_filters?
        @enabled_categories.empty? && @disabled_categories.empty?
      end

      # Apply enabled category filters
      def apply_enabled_category_filters(enabled)
        analyzers_with_metadata = @discovery.discover_analyzers_with_metadata
        category_enabled = Set.new

        analyzers_with_metadata.each do |key, info|
          category = info[:metadata][:category]
          category_enabled.add(key) if @enabled_categories.include?(category)
        end

        enabled & category_enabled
      end

      # Apply disabled category filters
      def apply_disabled_category_filters(enabled)
        analyzers_with_metadata = @discovery.discover_analyzers_with_metadata

        analyzers_with_metadata.each do |key, info|
          category = info[:metadata][:category]
          enabled.delete(key) if @disabled_categories.include?(category)
        end

        enabled
      end

      # Apply specific analyzer filters
      def apply_analyzer_filters(enabled)
        # If we have specifically enabled analyzers, use only those
        # BUT also consider category-enabled analyzers
        if @enabled_analyzers.any?
          # If we also have enabled categories, combine both
          if @enabled_categories.any?
            enabled &= (@enabled_analyzers | get_analyzers_in_enabled_categories)
          else
            enabled &= @enabled_analyzers
          end
        end

        # Remove specifically disabled analyzers
        enabled -= @disabled_analyzers

        enabled
      end

      # Get analyzers that belong to enabled categories
      def get_analyzers_in_enabled_categories
        return Set.new if @enabled_categories.empty?

        analyzers_with_metadata = @discovery.discover_analyzers_with_metadata
        category_analyzers = Set.new

        analyzers_with_metadata.each do |key, info|
          category = info[:metadata][:category]
          if @enabled_categories.include?(category)
            category_analyzers.add(key)
          end
        end

        category_analyzers
      end

      # Get analyzers that belong to a specific category
      def get_analyzers_in_category(category)
        analyzers_with_metadata = @discovery.discover_analyzers_with_metadata
        category_analyzers = Set.new

        analyzers_with_metadata.each do |key, info|
          if info[:metadata][:category] == category
            category_analyzers.add(key)
          end
        end

        category_analyzers
      end
    end
  end
end
