# frozen_string_literal: true

require 'test_helper'
require_relative '../../lib/rails_dependency_explorer/analysis/activerecord_relationship_analyzer'
require_relative '../../lib/rails_dependency_explorer/analysis/base_analyzer'

class ActiveRecordRelationshipAnalyzerMigrationTest < Minitest::Test
  def setup
    @dependency_data = {
      "User" => [{"ActiveRecord::has_many" => ["Post"]}, {"ActiveRecord::has_one" => ["Profile"]}],
      "Post" => [{"ActiveRecord::belongs_to" => ["User"]}, {"ActiveRecord::has_many" => ["Comment"]}],
      "Comment" => [{"ActiveRecord::belongs_to" => ["Post", "User"]}],
      "Profile" => [{"ActiveRecord::belongs_to" => ["User"]}]
    }
  end

  def test_activerecord_analyzer_inherits_from_base_analyzer
    analyzer = RailsDependencyExplorer::Analysis::ActiveRecordRelationshipAnalyzer.new(@dependency_data)
    
    # Should inherit from BaseAnalyzer
    assert_includes analyzer.class.ancestors, RailsDependencyExplorer::Analysis::BaseAnalyzer
  end

  def test_activerecord_analyzer_maintains_existing_api
    analyzer = RailsDependencyExplorer::Analysis::ActiveRecordRelationshipAnalyzer.new(@dependency_data, include_metadata: false)
    
    # Should still respond to existing methods
    assert_respond_to analyzer, :analyze_relationships
    assert_respond_to analyzer, :analyze
    
    # Both methods should return same result when metadata is disabled
    relationships_result = analyzer.analyze_relationships
    analyze_result = analyzer.analyze
    
    assert_equal relationships_result, analyze_result
  end

  def test_activerecord_analyzer_supports_base_analyzer_options
    # Should support error handling options
    analyzer = RailsDependencyExplorer::Analysis::ActiveRecordRelationshipAnalyzer.new(
      @dependency_data, 
      error_handling: :strict,
      include_metadata: false
    )
    
    assert_equal :strict, analyzer.options[:error_handling]
    assert_equal false, analyzer.options[:include_metadata]
  end

  def test_activerecord_analyzer_provides_metadata_when_requested
    analyzer = RailsDependencyExplorer::Analysis::ActiveRecordRelationshipAnalyzer.new(
      @dependency_data, 
      include_metadata: true
    )
    
    result = analyzer.analyze
    
    # Should include metadata wrapper
    assert_kind_of Hash, result
    assert_includes result.keys, :result
    assert_includes result.keys, :metadata
    
    # Metadata should include analyzer information
    metadata = result[:metadata]
    assert_equal "RailsDependencyExplorer::Analysis::ActiveRecordRelationshipAnalyzer", metadata[:analyzer_class]
    assert_equal 4, metadata[:dependency_count]
    assert_kind_of Time, metadata[:analysis_timestamp]
  end

  def test_activerecord_analyzer_returns_raw_result_without_metadata
    analyzer = RailsDependencyExplorer::Analysis::ActiveRecordRelationshipAnalyzer.new(
      @dependency_data, 
      include_metadata: false
    )
    
    result = analyzer.analyze
    
    # Should return raw relationship analysis result (hash with class names)
    assert_kind_of Hash, result

    # Should contain class names as keys
    assert_includes result.keys, "User"
    assert_includes result.keys, "Post"
    assert_includes result.keys, "Comment"
    assert_includes result.keys, "Profile"

    # Should not include metadata wrapper
    refute_includes result.keys, :result
    refute_includes result.keys, :metadata
  end

  def test_activerecord_analyzer_handles_errors_gracefully
    # Test with invalid dependency data
    analyzer = RailsDependencyExplorer::Analysis::ActiveRecordRelationshipAnalyzer.new(
      nil, 
      error_handling: :graceful
    )
    
    result = analyzer.analyze
    
    # Should return error result instead of raising
    assert_kind_of Hash, result
    assert_includes result.keys, :error
    assert_equal "Invalid dependency data provided to analyzer", result[:error][:message]
  end

  def test_activerecord_analyzer_raises_errors_in_strict_mode
    # Test with invalid dependency data
    analyzer = RailsDependencyExplorer::Analysis::ActiveRecordRelationshipAnalyzer.new(
      nil, 
      error_handling: :strict,
      validate_on_init: false  # Don't validate on init to test analyze-time validation
    )
    
    # Should raise error in strict mode
    assert_raises(StandardError) do
      analyzer.analyze
    end
  end

  def test_activerecord_analyzer_maintains_backward_compatibility
    analyzer = RailsDependencyExplorer::Analysis::ActiveRecordRelationshipAnalyzer.new(@dependency_data)
    
    # Should maintain existing analyze_relationships behavior
    relationships = analyzer.analyze_relationships
    
    # Should analyze ActiveRecord relationships correctly
    assert_kind_of Hash, relationships
    assert_includes relationships.keys, "User"
    assert_includes relationships.keys, "Post"
    assert_includes relationships.keys, "Comment"
    assert_includes relationships.keys, "Profile"

    # Should identify User relationships
    user_relationships = relationships["User"]
    assert_equal ["Post"], user_relationships[:has_many]
    assert_equal ["Profile"], user_relationships[:has_one]
    assert_empty user_relationships[:belongs_to]

    # Should identify Post relationships
    post_relationships = relationships["Post"]
    assert_equal ["Comment"], post_relationships[:has_many]
    assert_equal ["User"], post_relationships[:belongs_to]
    assert_empty post_relationships[:has_one]

    # Should identify Comment relationships
    comment_relationships = relationships["Comment"]
    assert_equal ["Post", "User"], comment_relationships[:belongs_to]
    assert_empty comment_relationships[:has_many]
    assert_empty comment_relationships[:has_one]
  end

  def test_activerecord_analyzer_implements_perform_analysis
    analyzer = RailsDependencyExplorer::Analysis::ActiveRecordRelationshipAnalyzer.new(@dependency_data)
    
    # Should implement perform_analysis method
    assert_respond_to analyzer, :perform_analysis
    
    # perform_analysis should return same result as analyze_relationships
    perform_result = analyzer.perform_analysis
    relationships_result = analyzer.analyze_relationships
    
    assert_equal relationships_result, perform_result
  end

  def test_activerecord_analyzer_maintains_relationship_analysis
    analyzer = RailsDependencyExplorer::Analysis::ActiveRecordRelationshipAnalyzer.new(@dependency_data)

    # Should still be able to analyze relationships
    assert_respond_to analyzer, :analyze_relationships

    relationships = analyzer.analyze_relationships
    assert_kind_of Hash, relationships
    assert_includes relationships.keys, "User"
    assert_includes relationships.keys, "Post"
  end
end
