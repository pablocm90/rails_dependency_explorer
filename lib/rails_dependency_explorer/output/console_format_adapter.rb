# frozen_string_literal: true

module RailsDependencyExplorer
  module Output
    class ConsoleFormatAdapter
      def format(graph_data)
        if graph_data[:nodes].empty?
          return "No dependencies found."
        end
        
        output = []
        output << "Dependencies found:"
        output << ""
        output << "Classes: #{graph_data[:nodes].join(', ')}"
        output << ""
        output << "Dependencies:"
        graph_data[:edges].each do |from, to|
          output << "  #{from} -> #{to}"
        end
        
        output.join("\n")
      end
    end
  end
end
