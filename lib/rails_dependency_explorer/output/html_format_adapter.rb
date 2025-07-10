# frozen_string_literal: true

module RailsDependencyExplorer
  module Output
    # Formats dependency analysis results into HTML format for web display.
    # Generates structured HTML with embedded CSS for presenting dependency information
    # in a web browser with proper formatting and navigation.
    class HtmlFormatAdapter
      def format(dependency_data, statistics = nil)
        dependencies_html = build_dependencies_html(dependency_data)
        statistics_html = build_statistics_html(statistics)

        <<~HTML
          <!DOCTYPE html>
          <html>
          <head>
            <title>Dependencies Report</title>
            <style>
              body { font-family: Arial, sans-serif; margin: 20px; }
              h1 { color: #333; }
              h2 { color: #666; }
              .dependency { margin: 10px 0; }
              .class-name { font-weight: bold; color: #0066cc; }
              .dependency-list { margin-left: 20px; }
              .statistic { margin: 5px 0; }
            </style>
          </head>
          <body>
            <h1>Dependencies Report</h1>
            
            <h2>Dependencies</h2>
            #{dependencies_html}
            
            <h2>Statistics</h2>
            #{statistics_html}
          </body>
          </html>
        HTML
      end

      def self.build_statistics_html(statistics)
        return "<p>No statistics available.</p>" if statistics.nil?

        html = ""
        html += "<div class='statistic'><strong>Total Classes:</strong> #{statistics[:total_classes]}</div>\n"
        html += "<div class='statistic'><strong>Total Dependencies:</strong> #{statistics[:total_dependencies]}</div>\n"
        html += "<div class='statistic'><strong>Most Used Dependency:</strong> #{statistics[:most_used_dependency]}</div>\n"
        html
      end

      def self.extract_unique_dependencies(dependencies)
        unique_deps = Set.new
        dependencies.each do |dep|
          if dep.is_a?(Hash)
            dep.each_key { |constant| unique_deps.add(constant) }
          end
        end
        unique_deps.to_a
      end

      private

      def build_dependencies_html(dependency_data)
        return "<p>No dependencies found.</p>" if dependency_data.empty?

        html = ""
        dependency_data.each do |class_name, dependencies|
          html += build_class_dependency_html(class_name, dependencies)
        end
        html
      end

      def build_class_dependency_html(class_name, dependencies)
        html = "<div class='dependency'>\n"
        html += "  <span class='class-name'>#{class_name}</span>\n"
        html += build_dependency_list_html(dependencies)
        html += "</div>\n"
        html
      end

      def build_dependency_list_html(dependencies)
        if dependencies.empty?
          "  <div class='dependency-list'>No dependencies</div>\n"
        else
          build_non_empty_dependency_list_html(dependencies)
        end
      end

      def build_non_empty_dependency_list_html(dependencies)
        html = "  <div class='dependency-list'>\n"
        unique_deps = extract_unique_dependencies(dependencies)
        unique_deps.each do |dep|
          html += "    <div>→ #{dep}</div>\n"
        end
        html += "  </div>\n"
        html
      end

      def build_statistics_html(statistics)
        self.class.build_statistics_html(statistics)
      end

      def extract_unique_dependencies(dependencies)
        self.class.extract_unique_dependencies(dependencies)
      end
    end
  end
end
