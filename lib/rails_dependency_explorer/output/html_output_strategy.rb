# frozen_string_literal: true

require_relative "output_strategy"
require_relative "html_format_adapter"

module RailsDependencyExplorer
  module Output
    # HTML output strategy for dependency visualization.
    # Formats dependency data into HTML format using the existing HtmlFormatAdapter.
    # Part of Phase 4.1 output strategy hierarchy implementation.
    class HtmlOutputStrategy < OutputStrategy
      def initialize
        @adapter = HtmlFormatAdapter.new
      end

      # Format dependency data into HTML format
      # @param dependency_data [Hash] The dependency data to format
      # @param statistics [Hash] Optional statistics data
      # @param architectural_analysis [Hash] Optional architectural analysis data
      # @return [String] HTML formatted output
      def format(dependency_data, statistics = nil, architectural_analysis: {})
        if has_architectural_analysis?(architectural_analysis)
          @adapter.format_with_architectural_analysis(dependency_data, statistics, architectural_analysis: architectural_analysis)
        else
          @adapter.format(dependency_data, statistics)
        end
      end
    end
  end
end
