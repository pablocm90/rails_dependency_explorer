# frozen_string_literal: true

require "set"
require_relative "dependency_graph_adapter"
require_relative "rails_aware_graph_adapter"
require_relative "dot_format_adapter"
require_relative "json_format_adapter"
require_relative "html_format_adapter"
require_relative "console_format_adapter"
require_relative "csv_format_adapter"

module RailsDependencyExplorer
  module Output
    # Main visualization coordinator for dependency analysis results.
    # Orchestrates the transformation of analysis data into various output formats
    # through specialized adapters, supporting JSON, HTML, DOT, and other formats.
    class DependencyVisualizer
      def to_graph(dependency_data)
        graph_adapter.to_graph(dependency_data)
      end

      def to_rails_graph(dependency_data)
        rails_graph_adapter.to_graph(dependency_data)
      end

      def to_dot(dependency_data)
        graph = to_graph(dependency_data)
        dot_adapter.format(graph)
      end

      def to_rails_dot(dependency_data)
        graph = to_rails_graph(dependency_data)
        dot_adapter.format(graph)
      end

      def to_json(dependency_data, statistics = nil)
        json_adapter.format(dependency_data, statistics)
      end

      def to_html(dependency_data, statistics = nil)
        html_adapter.format(dependency_data, statistics)
      end

      def to_console(dependency_data)
        graph = to_graph(dependency_data)
        ConsoleFormatAdapter.format(graph)
      end

      def to_csv(dependency_data, statistics = nil)
        csv_adapter.format(dependency_data, statistics)
      end

      # Architectural analysis enhanced output methods
      def to_json_with_architectural_analysis(dependency_data, statistics = nil, architectural_analysis = {})
        json_adapter.format_with_architectural_analysis(dependency_data, statistics, architectural_analysis: architectural_analysis)
      end

      def to_html_with_architectural_analysis(dependency_data, statistics = nil, architectural_analysis = {})
        html_adapter.format_with_architectural_analysis(dependency_data, statistics, architectural_analysis: architectural_analysis)
      end

      def to_dot_with_architectural_analysis(dependency_data, architectural_analysis = {})
        graph = to_graph(dependency_data)
        dot_adapter.format_with_architectural_analysis(graph, architectural_analysis: architectural_analysis)
      end

      def to_console_with_architectural_analysis(dependency_data, architectural_analysis = {})
        graph = to_graph(dependency_data)
        base_output = ConsoleFormatAdapter.format(graph)
        architectural_output = ConsoleFormatAdapter.format_architectural_analysis(architectural_analysis)
        "#{base_output}\n\n#{architectural_output}"
      end

      def to_csv_with_architectural_analysis(dependency_data, statistics = nil, architectural_analysis = {})
        csv_adapter.format_with_architectural_analysis(dependency_data, statistics, architectural_analysis: architectural_analysis)
      end

      private

      def graph_adapter
        @graph_adapter ||= DependencyGraphAdapter.new
      end

      def rails_graph_adapter
        @rails_graph_adapter ||= RailsAwareGraphAdapter.new
      end

      def dot_adapter
        @dot_adapter ||= DotFormatAdapter.new
      end

      def json_adapter
        @json_adapter ||= JsonFormatAdapter.new
      end

      def html_adapter
        @html_adapter ||= HtmlFormatAdapter.new
      end

      def csv_adapter
        @csv_adapter ||= CsvFormatAdapter.new
      end
    end
  end
end
