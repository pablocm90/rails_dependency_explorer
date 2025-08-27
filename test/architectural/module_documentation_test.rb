# frozen_string_literal: true

require "test_helper"

# Tests for module documentation completeness and quality.
# Ensures all major modules have proper documentation explaining their purpose,
# responsibilities, and architectural role within the system.
# Part of Phase 1.4 module documentation (Tidy First - Structural changes only).
class ModuleDocumentationTest < Minitest::Test
  def test_main_module_has_documentation
    # Test that the main RailsDependencyExplorer module has documentation
    main_module_file = File.read("lib/rails_dependency_explorer.rb")
    
    assert_match(/module RailsDependencyExplorer/, main_module_file,
      "Main module should be defined")
    
    # Should have module-level documentation
    assert_match(/# .*Rails Dependency Explorer.*/, main_module_file,
      "Main module should have descriptive documentation")
  end

  def test_analysis_module_has_documentation
    # Test that Analysis module has proper documentation
    analysis_files = Dir.glob("lib/rails_dependency_explorer/analysis/**/*.rb")
    analysis_result_file = analysis_files.find { |f| f.include?("analysis_result.rb") }
    
    refute_nil analysis_result_file, "AnalysisResult file should exist"
    
    content = File.read(analysis_result_file)
    assert_match(/module Analysis/, content,
      "Analysis module should be defined")
    
    # Should have module-level documentation explaining analysis responsibilities
    assert_match(/# .*analysis.*coordination.*/, content,
      "Analysis module should document its coordination responsibilities")
  end

  def test_parsing_module_has_documentation
    # Test that Parsing module has proper documentation
    parsing_files = Dir.glob("lib/rails_dependency_explorer/parsing/*.rb")
    dependency_parser_file = parsing_files.find { |f| f.include?("dependency_parser.rb") }
    
    refute_nil dependency_parser_file, "DependencyParser file should exist"
    
    content = File.read(dependency_parser_file)
    assert_match(/module Parsing/, content,
      "Parsing module should be defined")
    
    # Should have module-level documentation explaining parsing responsibilities
    assert_match(/# .*[Pp]arsing.*AST.*dependen/, content,
      "Parsing module should document its parsing responsibilities")
  end

  def test_output_module_has_documentation
    # Test that Output module has proper documentation
    output_files = Dir.glob("lib/rails_dependency_explorer/output/*.rb")
    
    refute_empty output_files, "Output module files should exist"
    
    # Check a representative output file for module documentation
    console_adapter_file = output_files.find { |f| f.include?("console_format_adapter.rb") }
    refute_nil console_adapter_file, "ConsoleFormatAdapter file should exist"
    
    content = File.read(console_adapter_file)
    assert_match(/module Output/, content,
      "Output module should be defined")
    
    # Should have module-level documentation explaining output formatting responsibilities
    assert_match(/# .*format.*output.*/, content,
      "Output module should document its formatting responsibilities")
  end

  def test_cli_module_has_documentation
    # Test that CLI module has proper documentation
    cli_files = Dir.glob("lib/rails_dependency_explorer/cli/*.rb")
    
    refute_empty cli_files, "CLI module files should exist"
    
    # Check a representative CLI file for module documentation
    command_file = cli_files.find { |f| f.include?("command.rb") }
    
    if command_file
      content = File.read(command_file)
      assert_match(/module CLI/, content,
        "CLI module should be defined")
      
      # Should have module-level documentation explaining CLI responsibilities
      assert_match(/# .*command.*interface.*/, content,
        "CLI module should document its command interface responsibilities")
    end
  end



  def test_architectural_analysis_module_has_documentation
    # Test that ArchitecturalAnalysis module has proper documentation
    arch_files = Dir.glob("lib/rails_dependency_explorer/architectural_analysis/*.rb")
    
    refute_empty arch_files, "ArchitecturalAnalysis module files should exist"
    
    # Check a representative architectural analysis file
    cross_namespace_file = arch_files.find { |f| f.include?("cross_namespace_cycle_analyzer.rb") }
    refute_nil cross_namespace_file, "CrossNamespaceCycleAnalyzer file should exist"
    
    content = File.read(cross_namespace_file)
    assert_match(/module ArchitecturalAnalysis/, content,
      "ArchitecturalAnalysis module should be defined")
    
    # Should have module-level documentation explaining architectural analysis purpose
    assert_match(/# .*architectural.*analysis.*/, content,
      "ArchitecturalAnalysis module should document its architectural analysis purpose")
  end

  def test_module_documentation_follows_consistent_format
    # Test that module documentation follows a consistent format
    module_files = [
      "lib/rails_dependency_explorer.rb",
      "lib/rails_dependency_explorer/utils.rb"
    ]
    
    module_files.each do |file|
      next unless File.exist?(file)
      
      content = File.read(file)
      
      # Should have frozen_string_literal comment
      assert_match(/# frozen_string_literal: true/, content,
        "#{file} should have frozen_string_literal comment")
      
      # Should have module documentation before module definition
      lines = content.split("\n")
      module_line_index = lines.find_index { |line| line.match(/^module /) }
      
      if module_line_index && module_line_index > 0
        # Check if there's documentation before the module definition
        preceding_lines = lines[0...module_line_index]
        has_documentation = preceding_lines.any? { |line| line.start_with?("# ") && !line.include?("frozen_string_literal") }
        
        assert has_documentation, "#{file} should have documentation before module definition"
      end
    end
  end

  def test_interface_modules_have_documentation
    # Test that interface modules have proper documentation
    interface_files = [
      "lib/rails_dependency_explorer/analysis/interfaces/analyzer_interface.rb",
      "lib/rails_dependency_explorer/analysis/interfaces/graph_analyzer_interface.rb",
      "lib/rails_dependency_explorer/analysis/interfaces/statistics_analyzer_interface.rb",
      "lib/rails_dependency_explorer/analysis/interfaces/component_analyzer_interface.rb"
    ]
    
    interface_files.each do |file|
      assert File.exist?(file), "#{file} should exist"
      
      content = File.read(file)
      
      # Should have module documentation explaining interface purpose
      assert_match(/# .*[Ii]nterface.*/, content,
        "#{file} should document its interface purpose")
      
      # Should define a module
      assert_match(/module \w+Interface/, content,
        "#{file} should define an interface module")
    end
  end

  def test_error_handler_module_has_documentation
    # Test that ErrorHandler module has proper documentation
    error_handler_file = "lib/rails_dependency_explorer/error_handler.rb"

    assert File.exist?(error_handler_file), "ErrorHandler module file should exist"

    content = File.read(error_handler_file)

    # Should have module documentation explaining error handling purpose
    assert_match(/# .*[Ee]rror.*handling.*/, content,
      "ErrorHandler should document its error handling purpose")

    # Should define ErrorHandler module
    assert_match(/module ErrorHandler/, content,
      "Should define ErrorHandler module")
  end
end
