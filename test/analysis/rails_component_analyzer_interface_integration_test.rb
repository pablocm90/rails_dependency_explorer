# frozen_string_literal: true

require 'test_helper'

class RailsComponentAnalyzerInterfaceIntegrationTest < Minitest::Test
  def setup
    @dependency_data = {
      "UsersController" => [{"ApplicationController" => [[]]}, {"User" => ["find", "create"]}, {"AuthService" => ["authenticate"]}],
      "User" => [{"ApplicationRecord" => [[]]}, {"Database" => ["save", "find"]}, {"ValidationService" => ["validate"]}],
      "AuthService" => [{"User" => ["find"]}, {"TokenService" => ["generate"]}],
      "TokenService" => [{"CryptoHelper" => ["encrypt"]}],
      "ValidationService" => [{"ValidationRules" => ["check"]}],
      "CryptoHelper" => [],
      "ValidationRules" => [],
      "Database" => []
    }
    @analyzer = RailsDependencyExplorer::Analysis::Analyzers::RailsComponentAnalyzer.new(@dependency_data)
  end

  def test_rails_component_analyzer_includes_component_analyzer_interface
    # Should include ComponentAnalyzerInterface
    assert @analyzer.class.included_modules.include?(RailsDependencyExplorer::Analysis::Interfaces::ComponentAnalyzerInterface)
  end

  def test_rails_component_analyzer_responds_to_component_interface_methods
    # Should respond to ComponentAnalyzerInterface methods
    assert_respond_to @analyzer, :classify_components
    assert_respond_to @analyzer, :analyze_component_relationships
    assert_respond_to @analyzer, :detect_layering_violations
  end

  def test_rails_component_analyzer_can_classify_components
    # Should be able to classify components using interface method
    classification = @analyzer.classify_components
    
    assert_kind_of Hash, classification
    assert_includes classification.keys, :controllers
    assert_includes classification.keys, :models
    assert_includes classification.keys, :services
    assert_includes classification.keys, :other

    # Verify component classification
    assert_includes classification[:controllers], "UsersController"
    assert_includes classification[:models], "User"
    assert_includes classification[:services], "AuthService"
    assert_includes classification[:services], "ValidationService"
    assert_includes classification[:services], "TokenService"
    assert_includes classification[:other], "CryptoHelper"
    assert_includes classification[:other], "ValidationRules"
    assert_includes classification[:other], "Database"
  end

  def test_rails_component_analyzer_can_analyze_component_relationships
    # Should be able to analyze component relationships using interface method
    relationships = @analyzer.analyze_component_relationships
    
    assert_kind_of Hash, relationships
    assert_includes relationships.keys, :controller_to_model
    assert_includes relationships.keys, :controller_to_service
    assert_includes relationships.keys, :service_to_model
    assert_includes relationships.keys, :service_to_service
    assert_includes relationships.keys, :cross_layer_dependencies
    
    # Verify relationship analysis
    assert_equal ["User"], relationships[:controller_to_model]["UsersController"]
    assert_equal ["AuthService"], relationships[:controller_to_service]["UsersController"]
    assert_equal ["User"], relationships[:service_to_model]["AuthService"]
    assert_equal ["TokenService"], relationships[:service_to_service]["AuthService"]
  end

  def test_rails_component_analyzer_can_detect_layering_violations
    # Should be able to detect layering violations using interface method
    violations = @analyzer.detect_layering_violations
    
    assert_kind_of Hash, violations
    assert_includes violations.keys, :violations_found
    assert_includes violations.keys, :violation_details
    assert_includes violations.keys, :severity_levels
    
    # Verify violation detection structure
    assert_kind_of Array, violations[:violations_found]
    assert_kind_of Hash, violations[:violation_details]
    assert_kind_of Hash, violations[:severity_levels]
  end

  def test_rails_component_analyzer_maintains_existing_functionality
    # Should still work with existing component analysis methods
    assert_respond_to @analyzer, :categorize_components

    # Should analyze components correctly using existing method
    components = @analyzer.categorize_components
    assert_kind_of Hash, components

    # Verify existing functionality is preserved
    assert_includes components.keys, :controllers
    assert_includes components.keys, :models
    assert_includes components.keys, :services
    assert_includes components.keys, :other
  end

  def test_rails_component_analyzer_interface_complements_existing_analysis
    # Interface methods should provide additional insights beyond existing analysis
    existing_analysis = @analyzer.categorize_components
    classification = @analyzer.classify_components
    relationships = @analyzer.analyze_component_relationships
    violations = @analyzer.detect_layering_violations

    # Classification should be consistent with existing analysis
    assert_equal existing_analysis[:controllers], classification[:controllers]
    assert_equal existing_analysis[:models], classification[:models]
    assert_equal existing_analysis[:services], classification[:services]
    assert_equal existing_analysis[:other], classification[:other]

    # Interface should provide additional insights
    assert_includes relationships.keys, :cross_layer_dependencies  # Enhanced analysis
    assert_includes violations.keys, :severity_levels  # Not in existing analysis
    assert_includes violations.keys, :violation_details  # Enhanced violation reporting
  end

  def test_rails_component_analyzer_can_use_both_interfaces
    # Should be able to use both existing and new interface methods

    # Use existing interface
    existing_analysis = @analyzer.categorize_components

    # Use component interface
    classification = @analyzer.classify_components
    relationships = @analyzer.analyze_component_relationships
    violations = @analyzer.detect_layering_violations

    # Both should provide consistent core information
    assert existing_analysis[:controllers].size > 0
    assert_equal existing_analysis[:controllers], classification[:controllers]
    assert_kind_of Hash, relationships
    assert_kind_of Hash, violations
  end

  def test_rails_component_analyzer_interface_methods_work_with_empty_data
    empty_analyzer = RailsDependencyExplorer::Analysis::Analyzers::RailsComponentAnalyzer.new({})
    
    # Component interface methods should handle empty data
    classification = empty_analyzer.classify_components
    assert_equal [], classification[:controllers]
    assert_equal [], classification[:models]
    assert_equal [], classification[:services]
    assert_equal [], classification[:other]
    
    relationships = empty_analyzer.analyze_component_relationships
    assert_equal({}, relationships[:controller_to_model])
    assert_equal({}, relationships[:controller_to_service])
    
    violations = empty_analyzer.detect_layering_violations
    assert_equal [], violations[:violations_found]
    assert_equal({}, violations[:violation_details])
  end

  def test_rails_component_analyzer_interface_methods_work_with_single_component
    single_component_data = {"UsersController" => [{"ApplicationController" => [[]]}]}
    single_analyzer = RailsDependencyExplorer::Analysis::Analyzers::RailsComponentAnalyzer.new(single_component_data)
    
    # Component interface should handle single component data
    classification = single_analyzer.classify_components
    assert_includes classification[:controllers], "UsersController"
    assert_includes classification[:controllers], "ApplicationController"  # Referenced class
    assert_equal [], classification[:models]
    assert_equal [], classification[:services]
    assert_equal [], classification[:other]
    
    relationships = single_analyzer.analyze_component_relationships
    assert_equal({}, relationships[:controller_to_model])
    assert_equal({}, relationships[:controller_to_service])
    
    violations = single_analyzer.detect_layering_violations
    assert_equal [], violations[:violations_found]  # No violations with single component
  end

  def test_rails_component_analyzer_interface_provides_enhanced_analysis
    # Interface should provide more detailed analysis than existing methods
    relationships = @analyzer.analyze_component_relationships
    violations = @analyzer.detect_layering_violations
    
    # Should provide detailed relationship analysis
    assert_kind_of Hash, relationships[:controller_to_model]
    assert_kind_of Hash, relationships[:controller_to_service]
    assert_kind_of Hash, relationships[:service_to_model]
    assert_kind_of Hash, relationships[:service_to_service]
    assert_kind_of Array, relationships[:cross_layer_dependencies]
    
    # Should provide violation analysis
    assert_kind_of Array, violations[:violations_found]
    assert_kind_of Hash, violations[:violation_details]
    assert_kind_of Hash, violations[:severity_levels]
    
    # Enhanced analysis should go beyond basic component listing
    cross_layer_deps = relationships[:cross_layer_dependencies]
    assert_kind_of Array, cross_layer_deps
  end

  def test_rails_component_analyzer_component_interface_identifies_patterns
    # Interface should identify architectural patterns and issues
    classification = @analyzer.classify_components
    relationships = @analyzer.analyze_component_relationships
    
    # Should identify component types correctly
    controllers = classification[:controllers]
    models = classification[:models]
    services = classification[:services]
    
    # Controllers should be identified
    assert controllers.any? { |c| c.include?("Controller") }
    
    # Models should be identified (classes without suffixes that aren't services)
    assert models.include?("User")

    # Services should be identified
    assert services.any? { |s| s.include?("Service") }
    
    # Should analyze relationships between component types
    controller_to_model = relationships[:controller_to_model]
    controller_to_service = relationships[:controller_to_service]
    
    # Should find controller->model relationships
    assert controller_to_model.any? { |controller, models| controller.include?("Controller") && models.any? }
    
    # Should find controller->service relationships
    assert controller_to_service.any? { |controller, services| controller.include?("Controller") && services.any? }
  end

  def test_rails_component_analyzer_detects_architectural_violations
    # Create data with potential layering violations
    violation_data = {
      "User" => [{"ApplicationRecord" => [[]]}, {"UsersController" => ["index"]}],  # Model depending on Controller (violation)
      "UsersController" => [{"ApplicationController" => [[]]}, {"User" => ["find"]}],   # Normal Controller->Model (OK)
      "AuthService" => [{"User" => ["authenticate"]}] # Service->Model (OK)
    }
    
    violation_analyzer = RailsDependencyExplorer::Analysis::Analyzers::RailsComponentAnalyzer.new(violation_data)
    violations = violation_analyzer.detect_layering_violations
    
    # Should detect the model->controller violation
    assert violations[:violations_found].size > 0, "Should detect layering violations"
    
    # Should provide details about violations
    violation_details = violations[:violation_details]
    assert_kind_of Hash, violation_details
    
    # Should categorize violation severity
    severity_levels = violations[:severity_levels]
    assert_kind_of Hash, severity_levels
    assert_includes severity_levels.keys, :high if violations[:violations_found].any?
  end

  def test_rails_component_analyzer_cross_layer_dependency_analysis
    # Interface should analyze cross-layer dependencies
    relationships = @analyzer.analyze_component_relationships
    cross_layer_deps = relationships[:cross_layer_dependencies]
    
    assert_kind_of Array, cross_layer_deps
    
    # Each cross-layer dependency should have source, target, and relationship type
    cross_layer_deps.each do |dependency|
      assert_kind_of Hash, dependency
      assert_includes dependency.keys, :source
      assert_includes dependency.keys, :target
      assert_includes dependency.keys, :relationship_type
    end
  end
end
