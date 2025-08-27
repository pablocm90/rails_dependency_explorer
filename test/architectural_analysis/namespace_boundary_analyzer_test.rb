# frozen_string_literal: true

require "test_helper"

# Test for namespace boundary violation detection
# Part of Test A2: Namespace boundary analysis
# Expected: Flag dependencies from App::Models to External::Services as potential violations
class NamespaceBoundaryAnalyzerTest < Minitest::Test
  def setup
    @dependency_data = namespace_boundary_violation_data
    @analyzer = RailsDependencyExplorer::Analysis::ArchitecturalAnalysis::NamespaceBoundaryAnalyzer.new(@dependency_data)
  end

  def test_namespace_boundary_analyzer_exists
    # RED: This test should fail because NamespaceBoundaryAnalyzer doesn't exist yet
    assert_respond_to @analyzer, :analyze
    assert_respond_to @analyzer, :boundary_violations
    assert_respond_to @analyzer, :violation_severity
  end

  def test_detects_cross_namespace_boundary_violations
    # RED: Test should fail - analyzer doesn't exist to detect violations
    violations = @analyzer.analyze

    # Should detect App::Models -> External::Services violation
    app_to_external_violation = violations.find do |violation|
      violation[:source_namespace] == "App::Models" &&
      violation[:target_namespace] == "External::Services"
    end

    assert app_to_external_violation, "Should detect App::Models -> External::Services boundary violation"
    assert_equal "User", app_to_external_violation[:source_class]
    assert_equal "PaymentGateway", app_to_external_violation[:target_class]
    assert_equal "high", app_to_external_violation[:severity]
  end

  def test_detects_internal_service_to_model_violations
    # RED: Test should fail - analyzer doesn't exist
    violations = @analyzer.analyze

    # Should detect Services -> App::Models violation (reverse dependency)
    service_to_model_violation = violations.find do |violation|
      violation[:source_namespace] == "Services" &&
      violation[:target_namespace] == "App::Models"
    end

    assert service_to_model_violation, "Should detect Services -> App::Models boundary violation"
    assert_equal "UserService", service_to_model_violation[:source_class]
    assert_equal "User", service_to_model_violation[:target_class]
    assert_equal "medium", service_to_model_violation[:severity]
  end

  def test_ignores_same_namespace_dependencies
    # RED: Test should fail - analyzer doesn't exist
    violations = @analyzer.analyze

    # Should not flag same-namespace dependencies as violations
    same_namespace_violations = violations.select do |violation|
      violation[:source_namespace] == violation[:target_namespace]
    end

    assert_empty same_namespace_violations, "Should not flag same-namespace dependencies as violations"
  end

  def test_calculates_violation_severity_based_on_namespace_distance
    # RED: Test should fail - analyzer doesn't exist
    violations = @analyzer.analyze

    # External dependencies should be high severity
    external_violations = violations.select { |v| v[:target_namespace].start_with?("External::") }
    external_violations.each do |violation|
      assert_equal "high", violation[:severity], "External dependencies should be high severity"
    end

    # Internal cross-namespace should be medium severity
    internal_violations = violations.select do |v|
      !v[:target_namespace].start_with?("External::") &&
      !v[:source_namespace].start_with?("External::") &&
      v[:source_namespace] != v[:target_namespace]
    end
    internal_violations.each do |violation|
      assert_equal "medium", violation[:severity], "Internal cross-namespace should be medium severity"
    end
  end

  def test_provides_violation_recommendations
    # RED: Test should fail - analyzer doesn't exist
    violations = @analyzer.analyze

    violations.each do |violation|
      assert violation.key?(:recommendation), "Each violation should have a recommendation"
      assert_instance_of String, violation[:recommendation]
      assert violation[:recommendation].length > 10, "Recommendation should be descriptive"
    end
  end

  def test_groups_violations_by_namespace_pair
    # RED: Test should fail - analyzer doesn't exist
    grouped_violations = @analyzer.violations_by_namespace_pair

    assert_instance_of Hash, grouped_violations
    
    # Should group App::Models -> External::Services violations
    app_to_external_key = "App::Models -> External::Services"
    assert grouped_violations.key?(app_to_external_key), "Should group violations by namespace pair"
    
    violations_in_group = grouped_violations[app_to_external_key]
    assert_instance_of Array, violations_in_group
    assert violations_in_group.size > 0, "Should have violations in the group"
  end

  def test_calculates_boundary_health_score
    # RED: Test should fail - analyzer doesn't exist
    health_score = @analyzer.boundary_health_score

    assert_instance_of Float, health_score
    assert health_score >= 0.0 && health_score <= 10.0, "Health score should be between 0.0 and 10.0"
    
    # With violations present, score should be less than perfect
    assert health_score < 10.0, "Health score should be reduced due to violations"
  end

  def test_handles_empty_dependency_data
    # RED: Test should fail - analyzer doesn't exist
    empty_analyzer = RailsDependencyExplorer::Analysis::ArchitecturalAnalysis::NamespaceBoundaryAnalyzer.new({})
    violations = empty_analyzer.analyze

    assert_instance_of Array, violations
    assert_empty violations, "Should return empty array for no dependencies"
    
    health_score = empty_analyzer.boundary_health_score
    assert_equal 10.0, health_score, "Perfect health score for no violations"
  end

  def test_integrates_with_analysis_result
    # RED: Test should fail - AnalysisResult doesn't have namespace boundary methods yet
    analysis_result = RailsDependencyExplorer::Analysis::Pipeline::AnalysisResult.new(@dependency_data)
    
    assert_respond_to analysis_result, :namespace_boundary_violations
    assert_respond_to analysis_result, :boundary_health_score
    
    violations = analysis_result.namespace_boundary_violations
    assert_instance_of Array, violations
    
    health_score = analysis_result.boundary_health_score
    assert_instance_of Float, health_score
  end

  private

  def namespace_boundary_violation_data
    {
      # App::Models accessing External services (HIGH violation)
      "App::Models::User" => [
        {"External::Services::PaymentGateway" => ["charge", "refund"]},
        {"External::APIs::EmailService" => ["send_notification"]},
        {"App::Models::Account" => ["find"]} # Same namespace - OK
      ],
      
      # Services accessing Models (MEDIUM violation - reverse dependency)
      "Services::UserService" => [
        {"App::Models::User" => ["create", "update"]},
        {"Services::ValidationService" => ["validate"]} # Same namespace - OK
      ],
      
      # Controllers accessing Services (OK - expected pattern)
      "App::Controllers::UsersController" => [
        {"Services::UserService" => ["create_user"]},
        {"App::Models::User" => ["find"]} # Direct model access - potential violation
      ],
      
      # External services accessing internal (HIGH violation)
      "External::Services::PaymentGateway" => [
        {"App::Models::User" => ["email", "name"]},
        {"Services::NotificationService" => ["notify"]}
      ],
      
      # Same namespace dependencies (should be ignored)
      "App::Models::Account" => [
        {"App::Models::User" => ["belongs_to"]},
        {"App::Models::Transaction" => ["has_many"]}
      ]
    }
  end
end
