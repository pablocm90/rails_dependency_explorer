# frozen_string_literal: true

require "test_helper"

class ActiveRecordRelationshipAnalyzerInterfaceIntegrationTest < Minitest::Test
  def setup
    # Test data with ActiveRecord relationships and Rails component patterns
    @dependency_data = {
      "User" => [
        {"ApplicationRecord" => ["validates"]},
        {"ActiveRecord::has_many" => ["Post", "Comment"]},
        {"ActiveRecord::has_one" => ["Profile"]},
        {"ActiveRecord::belongs_to" => ["Account"]}
      ],
      "Post" => [
        {"ApplicationRecord" => ["validates"]},
        {"ActiveRecord::belongs_to" => ["User"]},
        {"ActiveRecord::has_many" => ["Comment", "Tag"]}
      ],
      "Comment" => [
        {"ApplicationRecord" => ["validates"]},
        {"ActiveRecord::belongs_to" => ["Post", "User"]}
      ],
      "Profile" => [
        {"ApplicationRecord" => ["validates"]},
        {"ActiveRecord::belongs_to" => ["User"]}
      ],
      "Account" => [
        {"ApplicationRecord" => ["validates"]},
        {"ActiveRecord::has_many" => ["User"]}
      ],
      "Tag" => [
        {"ApplicationRecord" => ["validates"]},
        {"ActiveRecord::has_and_belongs_to_many" => ["Post"]}
      ],
      "UserController" => [
        {"ApplicationController" => ["before_action"]},
        {"User" => ["find", "create"]},
        {"UserService" => ["process"]}
      ],
      "UserService" => [
        {"User" => ["new", "save"]},
        {"EmailService" => ["send_notification"]}
      ],
      "EmailService" => [
        {"ActionMailer::Base" => ["deliver"]}
      ]
    }
    
    @analyzer = RailsDependencyExplorer::Analysis::ActiveRecordRelationshipAnalyzer.new(@dependency_data)
  end

  def test_activerecord_analyzer_includes_component_analyzer_interface
    # Should include ComponentAnalyzerInterface
    assert @analyzer.class.included_modules.include?(RailsDependencyExplorer::Analysis::ComponentAnalyzerInterface)
  end

  def test_activerecord_analyzer_responds_to_component_interface_methods
    # Should respond to ComponentAnalyzerInterface methods
    assert_respond_to @analyzer, :classify_components
    assert_respond_to @analyzer, :categorize_components
    assert_respond_to @analyzer, :analyze_component_relationships
    assert_respond_to @analyzer, :detect_layering_violations
    assert_respond_to @analyzer, :calculate_component_metrics
  end

  def test_activerecord_analyzer_classifies_components_correctly
    # Should classify components using Rails patterns
    classification = @analyzer.classify_components
    
    # Should identify models (inherit from ApplicationRecord)
    assert_includes classification[:models], "User"
    assert_includes classification[:models], "Post"
    assert_includes classification[:models], "Comment"
    assert_includes classification[:models], "Profile"
    assert_includes classification[:models], "Account"
    assert_includes classification[:models], "Tag"
    
    # Should identify controllers
    assert_includes classification[:controllers], "UserController"
    
    # Should identify services
    assert_includes classification[:services], "UserService"
    assert_includes classification[:services], "EmailService"
    
    # Should have proper structure
    assert_kind_of Array, classification[:models]
    assert_kind_of Array, classification[:controllers]
    assert_kind_of Array, classification[:services]
    assert_kind_of Array, classification[:other]
  end

  def test_activerecord_analyzer_analyzes_component_relationships
    # Should analyze relationships between component types
    relationships = @analyzer.analyze_component_relationships
    
    # Should have proper structure
    assert_kind_of Hash, relationships
    assert_includes relationships.keys, :controller_to_model
    assert_includes relationships.keys, :controller_to_service
    assert_includes relationships.keys, :service_to_model
    assert_includes relationships.keys, :service_to_service
    assert_includes relationships.keys, :model_to_model
    assert_includes relationships.keys, :other_relationships
    assert_includes relationships.keys, :cross_layer_dependencies
    
    # Should identify controller-to-model relationships
    assert_kind_of Hash, relationships[:controller_to_model]
    assert_includes relationships[:controller_to_model].keys, "UserController"
    assert_includes relationships[:controller_to_model]["UserController"], "User"
    
    # Should identify controller-to-service relationships
    assert_kind_of Hash, relationships[:controller_to_service]
    assert_includes relationships[:controller_to_service].keys, "UserController"
    assert_includes relationships[:controller_to_service]["UserController"], "UserService"
    
    # Should identify service-to-model relationships
    assert_kind_of Hash, relationships[:service_to_model]
    assert_includes relationships[:service_to_model].keys, "UserService"
    assert_includes relationships[:service_to_model]["UserService"], "User"
    
    # Should identify service-to-service relationships
    assert_kind_of Hash, relationships[:service_to_service]
    assert_includes relationships[:service_to_service].keys, "UserService"
    assert_includes relationships[:service_to_service]["UserService"], "EmailService"
  end

  def test_activerecord_analyzer_detects_layering_violations
    # Should detect architectural layering violations
    violations = @analyzer.detect_layering_violations
    
    # Should have proper structure
    assert_kind_of Hash, violations
    assert_includes violations.keys, :violations_found
    assert_includes violations.keys, :violation_details
    assert_includes violations.keys, :severity_levels
    
    # Should return arrays and hashes in proper format
    assert_kind_of Array, violations[:violations_found]
    assert_kind_of Hash, violations[:violation_details]
    assert_kind_of Hash, violations[:severity_levels]
  end

  def test_activerecord_analyzer_calculates_component_metrics
    # Should calculate component metrics
    metrics = @analyzer.calculate_component_metrics
    
    # Should have proper structure
    assert_kind_of Hash, metrics
    assert_includes metrics.keys, :component_counts
    assert_includes metrics.keys, :coupling_by_type
    assert_includes metrics.keys, :layering_violations
    
    # Should count components correctly
    counts = metrics[:component_counts]
    assert_equal 7, counts[:models]      # User, Post, Comment, Profile, Account, Tag, ApplicationRecord
    assert_equal 2, counts[:controllers] # UserController, ApplicationController
    assert_equal 2, counts[:services]    # UserService, EmailService
    
    # Should analyze coupling by type
    coupling = metrics[:coupling_by_type]
    assert_kind_of Hash, coupling
    assert_includes coupling.keys, :models
    assert_includes coupling.keys, :controllers
    assert_includes coupling.keys, :services
  end

  def test_activerecord_analyzer_interface_complements_existing_analysis
    # Interface methods should provide additional insights beyond existing analysis
    existing_analysis = @analyzer.analyze_relationships
    classification = @analyzer.classify_components
    relationships = @analyzer.analyze_component_relationships
    violations = @analyzer.detect_layering_violations
    
    # Should provide ActiveRecord relationship analysis
    assert_kind_of Hash, existing_analysis
    assert_includes existing_analysis.keys, "User"
    assert_includes existing_analysis["User"].keys, :has_many
    assert_includes existing_analysis["User"].keys, :has_one
    assert_includes existing_analysis["User"].keys, :belongs_to
    
    # Should provide component classification
    assert_kind_of Hash, classification
    assert classification[:models].size > 0
    
    # Should provide relationship analysis
    assert_kind_of Hash, relationships
    assert relationships[:controller_to_model].size > 0
    
    # Should provide violation detection
    assert_kind_of Hash, violations
  end

  def test_activerecord_analyzer_can_use_both_interfaces
    # Should be able to use both existing and new interface methods
    
    # Use existing interface (ActiveRecord relationships)
    existing_analysis = @analyzer.analyze_relationships
    
    # Use component interface (component classification and relationships)
    classification = @analyzer.classify_components
    relationships = @analyzer.analyze_component_relationships
    violations = @analyzer.detect_layering_violations
    metrics = @analyzer.calculate_component_metrics
    
    # Both should provide valuable information
    assert existing_analysis.keys.size > 0
    assert classification[:models].size > 0
    assert_kind_of Hash, relationships
    assert_kind_of Hash, violations
    assert_kind_of Hash, metrics
  end

  def test_activerecord_analyzer_interface_methods_work_with_empty_data
    empty_analyzer = RailsDependencyExplorer::Analysis::ActiveRecordRelationshipAnalyzer.new({})
    
    # Component interface methods should handle empty data
    classification = empty_analyzer.classify_components
    assert_equal [], classification[:controllers]
    assert_equal [], classification[:models]
    assert_equal [], classification[:services]
    assert_equal [], classification[:other]
    
    relationships = empty_analyzer.analyze_component_relationships
    assert_equal({}, relationships[:controller_to_model])
    assert_equal({}, relationships[:controller_to_service])
    assert_equal [], relationships[:cross_layer_dependencies]
    
    violations = empty_analyzer.detect_layering_violations
    assert_equal [], violations[:violations_found]
    assert_equal({}, violations[:violation_details])
    
    metrics = empty_analyzer.calculate_component_metrics
    assert_equal 0, metrics[:component_counts][:controllers]
    assert_equal 0, metrics[:component_counts][:models]
    assert_equal 0, metrics[:component_counts][:services]
  end

  def test_activerecord_analyzer_interface_handles_single_component
    single_component_data = {
      "User" => [
        {"ApplicationRecord" => ["validates"]},
        {"ActiveRecord::has_many" => ["Post"]}
      ]
    }
    
    single_analyzer = RailsDependencyExplorer::Analysis::ActiveRecordRelationshipAnalyzer.new(single_component_data)
    
    # Should handle single component correctly
    classification = single_analyzer.classify_components
    assert_includes classification[:models], "User"
    assert_equal 2, classification[:models].size  # User + ApplicationRecord

    relationships = single_analyzer.analyze_component_relationships
    assert_kind_of Hash, relationships

    metrics = single_analyzer.calculate_component_metrics
    assert_equal 2, metrics[:component_counts][:models]  # User + ApplicationRecord
    assert_equal 0, metrics[:component_counts][:controllers]
  end

  def test_activerecord_analyzer_interface_provides_enhanced_analysis
    # Interface should provide more detailed analysis than existing methods
    relationships = @analyzer.analyze_component_relationships
    violations = @analyzer.detect_layering_violations
    
    # Should provide detailed relationship analysis
    assert_kind_of Hash, relationships[:controller_to_model]
    assert_kind_of Hash, relationships[:controller_to_service]
    assert_kind_of Hash, relationships[:service_to_model]
    assert_kind_of Hash, relationships[:service_to_service]
    assert_kind_of Hash, relationships[:model_to_model]
    assert_kind_of Array, relationships[:cross_layer_dependencies]
    
    # Should provide violation analysis
    assert_kind_of Array, violations[:violations_found]
    assert_kind_of Hash, violations[:violation_details]
    assert_kind_of Hash, violations[:severity_levels]
  end

  def test_activerecord_analyzer_component_interface_identifies_patterns
    # Interface should identify architectural patterns and issues
    classification = @analyzer.classify_components
    relationships = @analyzer.analyze_component_relationships
    
    # Should identify component types correctly
    models = classification[:models]
    controllers = classification[:controllers]
    services = classification[:services]
    
    # Models should be identified (classes that inherit from ApplicationRecord)
    assert models.include?("User")
    assert models.include?("Post")
    assert models.include?("Comment")
    
    # Controllers should be identified
    assert controllers.any? { |c| c.include?("Controller") }
    
    # Services should be identified
    assert services.any? { |s| s.include?("Service") }
    
    # Should identify relationships between different component types
    assert relationships[:controller_to_model].keys.size > 0
    assert relationships[:service_to_model].keys.size > 0
  end

  def test_activerecord_analyzer_interface_detects_architectural_violations
    # Interface should detect architectural violations and cross-layer dependencies
    violations = @analyzer.detect_layering_violations
    relationships = @analyzer.analyze_component_relationships
    
    # Should detect violations if any exist
    assert_kind_of Array, violations[:violations_found]
    assert_kind_of Hash, violations[:violation_details]
    
    # Should track cross-layer dependencies
    assert_kind_of Array, relationships[:cross_layer_dependencies]
    
    # Should provide severity classification
    assert_kind_of Hash, violations[:severity_levels]
  end

  def test_activerecord_analyzer_interface_analyzes_cross_layer_dependencies
    # Interface should analyze dependencies that cross architectural layers
    relationships = @analyzer.analyze_component_relationships
    
    # Should track cross-layer dependencies
    cross_layer = relationships[:cross_layer_dependencies]
    assert_kind_of Array, cross_layer
    
    # Each cross-layer dependency should have proper structure
    cross_layer.each do |dependency|
      assert_includes dependency.keys, :source
      assert_includes dependency.keys, :target
      assert_includes dependency.keys, :relationship_type
    end
  end
end
