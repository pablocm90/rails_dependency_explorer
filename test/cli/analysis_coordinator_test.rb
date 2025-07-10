# frozen_string_literal: true

require "test_helper"
require "tempfile"

class AnalysisCoordinatorTest < Minitest::Test
  def setup
    @output_writer = RailsDependencyExplorer::CLI::OutputWriter.new
  end

  def test_coordinate_analysis_file_returns_0_on_success
    with_test_file do |file|
      parser = create_parser_mock(file_path: file.path, format: "json")
      coordinator = RailsDependencyExplorer::CLI::AnalysisCoordinator.new(parser, @output_writer)
      
      result = coordinator.coordinate_analysis(:file)
      assert_equal 0, result
    end
  end

  def test_coordinate_analysis_file_returns_1_on_invalid_path
    parser = create_parser_mock(file_path: nil, format: "json")
    coordinator = RailsDependencyExplorer::CLI::AnalysisCoordinator.new(parser, @output_writer)
    
    result = coordinator.coordinate_analysis(:file)
    assert_equal 1, result
  end

  def test_coordinate_analysis_directory_returns_0_on_success
    Dir.mktmpdir do |dir|
      create_test_file_in_directory(dir, "test.rb", "class TestClass; end")
      parser = create_parser_mock(directory_path: dir, format: "json")
      coordinator = RailsDependencyExplorer::CLI::AnalysisCoordinator.new(parser, @output_writer)
      
      result = coordinator.coordinate_analysis(:directory)
      assert_equal 0, result
    end
  end

  def test_coordinate_analysis_directory_returns_1_on_invalid_path
    parser = create_parser_mock(directory_path: "nonexistent", format: "json")
    coordinator = RailsDependencyExplorer::CLI::AnalysisCoordinator.new(parser, @output_writer)
    
    result = coordinator.coordinate_analysis(:directory)
    assert_equal 1, result
  end

  def test_analysis_executor_is_accessible
    parser = create_parser_mock
    coordinator = RailsDependencyExplorer::CLI::AnalysisCoordinator.new(parser, @output_writer)
    
    assert_instance_of RailsDependencyExplorer::CLI::AnalysisExecutor, coordinator.analysis_executor
  end

  private

  def create_parser_mock(file_path: nil, directory_path: nil, format: "json", output_file: nil)
    parser = Object.new
    
    def parser.get_file_path; @file_path; end
    def parser.get_directory_path; @directory_path; end
    def parser.parse_format_option; @format; end
    def parser.parse_output_option; @output_file; end
    def parser.has_stats_option?; false; end
    def parser.has_circular_option?; false; end
    def parser.has_depth_option?; false; end
    
    parser.instance_variable_set(:@file_path, file_path)
    parser.instance_variable_set(:@directory_path, directory_path)
    parser.instance_variable_set(:@format, format)
    parser.instance_variable_set(:@output_file, output_file)
    
    parser
  end

  def with_test_file
    file = Tempfile.new(["test", ".rb"])
    file.write("class TestClass; end")
    file.close
    yield file
  ensure
    file&.unlink
  end

  def create_test_file_in_directory(dir, filename, content)
    file_path = File.join(dir, filename)
    File.write(file_path, content)
  end
end
