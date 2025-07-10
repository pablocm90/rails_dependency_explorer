# frozen_string_literal: true

module RailsDependencyExplorer
  module Output
    # Formats dependency analysis results into CSV format for spreadsheet analysis.
    # Converts dependency data into comma-separated values with proper headers,
    # suitable for import into Excel, Google Sheets, and other data analysis tools.
    class CsvFormatAdapter
      def format(dependency_data, statistics = nil)
        csv_lines = ["Source,Target,Methods"]
        
        dependency_data.each do |class_name, dependencies|
          add_dependency_rows(csv_lines, class_name, dependencies)
        end
        
        csv_lines.join("\n")
      end

      private

      def add_dependency_rows(csv_lines, class_name, dependencies)
        dependencies.each do |dependency_hash|
          dependency_hash.each do |target_class, methods|
            methods_list = methods.join(";")
            csv_lines << "#{class_name},#{target_class},#{methods_list}"
          end
        end
      end
    end
  end
end
