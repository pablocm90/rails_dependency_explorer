# frozen_string_literal: true

module RailsDependencyExplorer
  module CLI
    class OutputWriter
      def write_output(content, output_file)
        if output_file.nil?
          # Write to stdout
          puts content
        else
          # Write to file
          begin
            File.write(output_file, content)
          rescue => e
            puts "Error writing to file '#{output_file}': #{e.message}"
            raise e
          end
        end
      end

      def format_output(result, format)
        case format
        when "dot"
          result.to_dot
        when "json"
          result.to_json
        when "html"
          result.to_html
        when "graph"
          result.to_console
        else
          result.to_console
        end
      end
    end
  end
end
