# frozen_string_literal: true

require "set"
require_relative "dependency_graph_adapter"
require_relative "dot_format_adapter"
require_relative "json_format_adapter"
require_relative "html_format_adapter"
require_relative "console_format_adapter"

module RailsDependencyExplorer
  module Output
    class DependencyVisualizer
      def to_graph(dependency_data)
        graph_adapter.to_graph(dependency_data)
      end

      def to_dot(dependency_data)
        graph = to_graph(dependency_data)
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
        console_adapter.format(graph)
      end

      private

      def graph_adapter
        @graph_adapter ||= DependencyGraphAdapter.new
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

      def console_adapter
        @console_adapter ||= ConsoleFormatAdapter.new
      end
    end
  end
end
