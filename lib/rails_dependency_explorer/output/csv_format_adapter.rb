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

      def format_with_architectural_analysis(dependency_data, statistics = nil, architectural_analysis: {})
        csv_lines = ["From,To,Methods,Cross_Namespace_Cycle,Cycle_Severity,Affected_Namespaces"]

        dependency_data.each do |class_name, dependencies|
          add_dependency_rows_with_architectural_analysis(csv_lines, class_name, dependencies, architectural_analysis)
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

      def add_dependency_rows_with_architectural_analysis(csv_lines, class_name, dependencies, architectural_analysis)
        cross_namespace_cycle_edges = extract_cross_namespace_cycle_info(architectural_analysis)

        dependencies.each do |dependency_hash|
          dependency_hash.each do |target_class, methods|
            methods_list = methods.join(";")

            # Check if this edge is part of a cross-namespace cycle
            edge_key = [class_name, target_class]
            if cross_namespace_cycle_edges.key?(edge_key)
              cycle_info = cross_namespace_cycle_edges[edge_key]
              csv_lines << "#{class_name},#{target_class},#{methods_list},Yes,#{cycle_info[:severity]},\"#{cycle_info[:namespaces].join(', ')}\""
            else
              csv_lines << "#{class_name},#{target_class},#{methods_list},No,\"\",\"\""
            end
          end
        end
      end

      def extract_cross_namespace_cycle_info(architectural_analysis)
        edge_info = {}
        return edge_info unless architectural_analysis[:cross_namespace_cycles]

        architectural_analysis[:cross_namespace_cycles].each do |cycle_info|
          cycle = cycle_info[:cycle]
          (0...cycle.length - 1).each do |i|
            edge_key = [cycle[i], cycle[i + 1]]
            edge_info[edge_key] = {
              severity: cycle_info[:severity],
              namespaces: cycle_info[:namespaces]
            }
          end
        end
        edge_info
      end
    end
  end
end
