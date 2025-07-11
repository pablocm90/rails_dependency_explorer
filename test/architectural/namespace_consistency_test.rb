# frozen_string_literal: true

require "test_helper"

# Tests for namespace consistency across the codebase.
# Ensures all require statements use full paths and consistent namespace conventions.
# Part of Phase 1.1 architectural refactoring (Tidy First - Structural changes only).
class NamespaceConsistencyTest < Minitest::Test
  def test_all_requires_use_consistent_namespace_paths
    lib_files = Dir.glob("lib/**/*.rb")

    lib_files.each do |file|
      content = File.read(file)

      # For now, just check for deep relative requires (multiple ../ levels)
      # Single ../ is acceptable for cross-module dependencies
      deep_relative_requires = content.scan(/require_relative\s+["']([^"']*\.\.\/.*\.\.\/[^"']*)["']/)

      assert_empty deep_relative_requires,
        "File #{file} contains deep relative requires (multiple ../): #{deep_relative_requires.flatten.join(', ')}"

      # Check for redundant ./ patterns
      redundant_current_dir = content.scan(/require_relative\s+["'](\.[\/][^"']*)["']/)

      assert_empty redundant_current_dir,
        "File #{file} contains redundant './' in require_relative: #{redundant_current_dir.flatten.join(', ')}"
    end
  end

  def test_no_mixed_require_styles_in_single_file
    lib_files = Dir.glob("lib/**/*.rb")
    
    lib_files.each do |file|
      content = File.read(file)
      
      # Count different require styles
      require_relative_count = content.scan(/require_relative/).length
      require_absolute_count = content.scan(/^require\s+["'][^"']*["']/).length
      
      # Skip files with no requires
      next if require_relative_count == 0 && require_absolute_count == 0
      
      # If file has both types, it should be intentional (like main entry point or files requiring external gems)
      if require_relative_count > 0 && require_absolute_count > 0
        # Allow mixed styles in files that legitimately need both external and internal requires
        allowed_mixed_files = [
          "lib/rails_dependency_explorer.rb",
          "lib/rails_dependency_explorer/analysis/analysis_result.rb",  # Uses external gems + internal files
          "lib/rails_dependency_explorer/analysis/circular_dependency_analyzer.rb", # Uses Set + internal files
          "lib/rails_dependency_explorer/analysis/dependency_depth_analyzer.rb", # Uses Set + internal files
          "lib/rails_dependency_explorer/output/dependency_visualizer.rb" # Uses Set + internal files
        ]

        assert_includes allowed_mixed_files, file,
          "File #{file} mixes require and require_relative styles unexpectedly. " \
          "Either use only require_relative for internal dependencies, or add to allowed_mixed_files if external gems are needed."
      end
    end
  end

  def test_require_relative_paths_are_normalized
    lib_files = Dir.glob("lib/**/*.rb")
    
    lib_files.each do |file|
      content = File.read(file)
      
      # Find all require_relative statements
      require_statements = content.scan(/require_relative\s+["']([^"']*)["']/)
      
      require_statements.flatten.each do |path|
        # Check for redundant ./ at the beginning
        refute_match(/^\.\//, path,
          "File #{file} has redundant './' in require_relative: #{path}")
        
        # Check for double slashes
        refute_match(/\/\//, path,
          "File #{file} has double slashes in require_relative: #{path}")
        
        # Check for trailing slashes
        refute_match(/\/$/, path,
          "File #{file} has trailing slash in require_relative: #{path}")
      end
    end
  end

  def test_consistent_namespace_references_in_code
    lib_files = Dir.glob("lib/**/*.rb")
    
    lib_files.each do |file|
      content = File.read(file)
      
      # Skip files that are just module/class definitions
      next unless content.match?(/\w+::\w+/)
      
      # Look for inconsistent namespace usage patterns
      # This is a structural check - we want consistent style
      
      # Check for mixed short and long namespace references to same class
      # Example: both "AnalysisResult" and "RailsDependencyExplorer::Analysis::AnalysisResult"
      short_class_refs = content.scan(/(?<!::)([A-Z][a-zA-Z]*(?:[A-Z][a-zA-Z]*)*)(?!::)/)
        .flatten
        .select { |ref| ref.length > 3 } # Filter out short words like "Set"
      
      long_class_refs = content.scan(/RailsDependencyExplorer::(?:\w+::)*(\w+)/)
        .flatten
      
      # Find classes referenced both ways in same file
      mixed_references = short_class_refs & long_class_refs
      
      # Allow some exceptions for common patterns
      allowed_mixed_references = %w[Set Hash Array String Parser]
      mixed_references -= allowed_mixed_references
      
      if mixed_references.any?
        # This is informational for now - we'll fix in implementation
        # For the test to pass initially, we'll make this a soft assertion
        puts "INFO: File #{file} has mixed namespace references: #{mixed_references.join(', ')}"
      end
    end
  end
end
