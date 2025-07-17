# frozen_string_literal: true

require 'test_helper'
require_relative '../../lib/rails_dependency_explorer/analysis/component_analyzer_interface'

class ComponentAnalyzerInterfaceTest < Minitest::Test
  def test_component_analyzer_interface_exists
    # Interface should be defined
    assert_kind_of Module, RailsDependencyExplorer::Analysis::ComponentAnalyzerInterface
  end

  def test_component_analyzer_interface_defines_required_methods
    interface = RailsDependencyExplorer::Analysis::ComponentAnalyzerInterface
    
    # Should define method requirements for component analysis
    assert_respond_to interface, :included
    
    # When included, should add required methods
    test_class = Class.new do
      include RailsDependencyExplorer::Analysis::ComponentAnalyzerInterface
    end
    
    instance = test_class.new
    
    # Should require categorize_components method
    assert_respond_to instance, :categorize_components
    
    # Should require classify_component method
    assert_respond_to instance, :classify_component
    
    # Should require analyze_component_relationships method
    assert_respond_to instance, :analyze_component_relationships
  end

  def test_component_analyzer_interface_provides_component_categorization
    test_class = Class.new do
      include RailsDependencyExplorer::Analysis::ComponentAnalyzerInterface
      
      def initialize(dependency_data)
        @dependency_data = dependency_data
      end
    end
    
    dependency_data = {
      "UserController" => [{"User" => ["find"]}, {"UserService" => ["create"]}],
      "User" => [{"ActiveRecord::Base" => ["validates"]}],
      "UserService" => [{"User" => ["new"]}, {"EmailService" => ["send"]}],
      "EmailService" => [{"ActionMailer::Base" => ["deliver"]}],
      "ApplicationController" => [{"ActionController::Base" => ["before_action"]}]
    }
    
    instance = test_class.new(dependency_data)
    
    # Should categorize components by type
    categories = instance.categorize_components
    
    assert_kind_of Hash, categories
    assert_includes categories.keys, :controllers
    assert_includes categories.keys, :models
    assert_includes categories.keys, :services
    assert_includes categories.keys, :other
    
    # Should categorize correctly
    assert_includes categories[:controllers], "UserController"
    assert_includes categories[:controllers], "ApplicationController"
    assert_includes categories[:models], "User"
    assert_includes categories[:services], "UserService"
    assert_includes categories[:services], "EmailService"
  end

  def test_component_analyzer_interface_provides_component_classification
    test_class = Class.new do
      include RailsDependencyExplorer::Analysis::ComponentAnalyzerInterface
      
      def initialize(dependency_data)
        @dependency_data = dependency_data
      end
    end
    
    dependency_data = {
      "UserController" => [{"User" => ["find"]}],
      "User" => [{"ActiveRecord::Base" => ["validates"]}],
      "UserService" => [{"User" => ["new"]}]
    }
    
    instance = test_class.new(dependency_data)
    
    # Should classify individual components
    assert_equal :controller, instance.classify_component("UserController")
    assert_equal :model, instance.classify_component("User")
    assert_equal :service, instance.classify_component("UserService")
    assert_equal :other, instance.classify_component("UnknownClass")
  end

  def test_component_analyzer_interface_analyzes_component_relationships
    test_class = Class.new do
      include RailsDependencyExplorer::Analysis::ComponentAnalyzerInterface
      
      def initialize(dependency_data)
        @dependency_data = dependency_data
      end
    end
    
    dependency_data = {
      "UserController" => [{"User" => ["find"]}, {"UserService" => ["create"]}],
      "User" => [{"ActiveRecord::Base" => ["validates"]}],
      "UserService" => [{"User" => ["new"]}, {"EmailService" => ["send"]}],
      "EmailService" => [{"ActionMailer::Base" => ["deliver"]}]
    }
    
    instance = test_class.new(dependency_data)
    
    # Should analyze relationships between component types
    relationships = instance.analyze_component_relationships
    
    assert_kind_of Hash, relationships
    assert_includes relationships.keys, :controller_to_model
    assert_includes relationships.keys, :controller_to_service
    assert_includes relationships.keys, :service_to_model
    assert_includes relationships.keys, :service_to_service
    
    # Should identify specific relationships
    assert_equal ["User"], relationships[:controller_to_model]["UserController"]
    assert_equal ["UserService"], relationships[:controller_to_service]["UserController"]
    assert_equal ["User"], relationships[:service_to_model]["UserService"]
    assert_equal ["EmailService"], relationships[:service_to_service]["UserService"]
  end

  def test_component_analyzer_interface_provides_component_metrics
    test_class = Class.new do
      include RailsDependencyExplorer::Analysis::ComponentAnalyzerInterface
      
      def initialize(dependency_data)
        @dependency_data = dependency_data
      end
    end
    
    dependency_data = {
      "UserController" => [{"User" => ["find"]}, {"UserService" => ["create"]}],
      "User" => [{"ActiveRecord::Base" => ["validates"]}],
      "UserService" => [{"User" => ["new"]}, {"EmailService" => ["send"]}],
      "EmailService" => [{"ActionMailer::Base" => ["deliver"]}]
    }
    
    instance = test_class.new(dependency_data)
    
    # Should provide component metrics
    metrics = instance.calculate_component_metrics
    
    assert_kind_of Hash, metrics
    assert_includes metrics.keys, :component_counts
    assert_includes metrics.keys, :coupling_by_type
    assert_includes metrics.keys, :layering_violations
    
    # Should count components by type (including referenced classes)
    counts = metrics[:component_counts]
    assert_equal 1, counts[:controllers]  # UserController only
    assert_equal 2, counts[:models]       # User + ActiveRecord::Base (referenced)
    assert_equal 2, counts[:services]     # UserService + EmailService
    assert_equal 1, counts[:other]        # ActionMailer::Base (referenced)
    
    # Should analyze coupling by component type
    coupling = metrics[:coupling_by_type]
    assert_includes coupling.keys, :controllers
    assert_includes coupling.keys, :models
    assert_includes coupling.keys, :services
  end

  def test_component_analyzer_interface_handles_empty_data
    test_class = Class.new do
      include RailsDependencyExplorer::Analysis::ComponentAnalyzerInterface
      
      def initialize(dependency_data)
        @dependency_data = dependency_data
      end
    end
    
    instance = test_class.new({})
    
    # Should handle empty dependency data gracefully
    categories = instance.categorize_components
    assert_equal({controllers: [], models: [], services: [], other: []}, categories)
    
    relationships = instance.analyze_component_relationships
    expected_relationships = {
      controller_to_model: {},
      controller_to_service: {},
      service_to_model: {},
      service_to_service: {},
      model_to_model: {},
      other_relationships: {},
      cross_layer_dependencies: []
    }
    assert_equal expected_relationships, relationships
    
    metrics = instance.calculate_component_metrics
    assert_equal 0, metrics[:component_counts][:controllers]
    assert_equal 0, metrics[:component_counts][:models]
    assert_equal 0, metrics[:component_counts][:services]
  end

  def test_component_analyzer_interface_detects_layering_violations
    test_class = Class.new do
      include RailsDependencyExplorer::Analysis::ComponentAnalyzerInterface
      
      def initialize(dependency_data)
        @dependency_data = dependency_data
      end
    end
    
    # Create data with layering violations (model depending on controller)
    dependency_data = {
      "UserController" => [{"User" => ["find"]}],
      "User" => [{"UserController" => ["redirect_to"]}],  # Violation: model -> controller
      "UserService" => [{"UserController" => ["params"]}]  # Violation: service -> controller
    }
    
    instance = test_class.new(dependency_data)
    
    metrics = instance.calculate_component_metrics
    violations = metrics[:layering_violations]
    
    assert_kind_of Array, violations
    assert violations.any? { |v| v[:from] == "User" && v[:to] == "UserController" }
    assert violations.any? { |v| v[:from] == "UserService" && v[:to] == "UserController" }
  end
end
