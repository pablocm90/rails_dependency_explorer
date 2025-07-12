# frozen_string_literal: true

require "test_helper"

# Tests for dependency injection container functionality.
# Ensures proper service registration, resolution, lazy loading, and caching.
# Part of Phase 2.1 dependency injection implementation (TDD - Behavioral changes).
class DependencyContainerTest < Minitest::Test
  def setup
    @container = RailsDependencyExplorer::Analysis::DependencyContainer.new
    @dependency_data = { "TestClass" => ["Dependency1", "Dependency2"] }
  end

  def test_dependency_container_registration
    # Test basic service registration and resolution
    @container.register(:circular_analyzer) do |data|
      RailsDependencyExplorer::Analysis::CircularDependencyAnalyzer.new(data)
    end
    
    analyzer = @container.resolve(:circular_analyzer, @dependency_data)
    assert_instance_of RailsDependencyExplorer::Analysis::CircularDependencyAnalyzer, analyzer
  end

  def test_dependency_container_lazy_loading
    # Test that services are not created until resolved
    creation_count = 0
    @container.register(:test_service) do
      creation_count += 1
      "service_instance"
    end
    
    # Should not create until resolved
    assert_equal 0, creation_count
    
    service = @container.resolve(:test_service)
    assert_equal 1, creation_count
    assert_equal "service_instance", service
  end

  def test_dependency_container_caching
    # Test that resolved services are cached
    creation_count = 0
    @container.register(:cached_service) do
      creation_count += 1
      "cached_instance"
    end
    
    # First resolution should create the service
    service1 = @container.resolve(:cached_service)
    assert_equal 1, creation_count
    assert_equal "cached_instance", service1
    
    # Second resolution should return cached instance
    service2 = @container.resolve(:cached_service)
    assert_equal 1, creation_count  # Should not increment
    assert_same service1, service2  # Should be same object
  end

  def test_dependency_container_with_parameters
    # Test service registration with parameters
    @container.register(:parameterized_service) do |param1, param2|
      "service_with_#{param1}_#{param2}"
    end
    
    service = @container.resolve(:parameterized_service, "param_a", "param_b")
    assert_equal "service_with_param_a_param_b", service
  end

  def test_dependency_container_unregistered_service
    # Test behavior when resolving unregistered service
    assert_raises(RailsDependencyExplorer::Analysis::DependencyContainer::ServiceNotRegisteredError) do
      @container.resolve(:unregistered_service)
    end
  end

  def test_dependency_container_service_registration_override
    # Test that service registration can be overridden
    @container.register(:overridable_service) { "original_service" }
    @container.register(:overridable_service) { "overridden_service" }
    
    service = @container.resolve(:overridable_service)
    assert_equal "overridden_service", service
  end

  def test_dependency_container_multiple_services
    # Test registration and resolution of multiple services
    @container.register(:service_a) { "service_a_instance" }
    @container.register(:service_b) { "service_b_instance" }
    @container.register(:service_c) { "service_c_instance" }
    
    assert_equal "service_a_instance", @container.resolve(:service_a)
    assert_equal "service_b_instance", @container.resolve(:service_b)
    assert_equal "service_c_instance", @container.resolve(:service_c)
  end

  def test_dependency_container_registered_services
    # Test ability to query registered services
    @container.register(:service_1) { "service_1" }
    @container.register(:service_2) { "service_2" }
    
    registered_services = @container.registered_services
    assert_includes registered_services, :service_1
    assert_includes registered_services, :service_2
    assert_equal 2, registered_services.size
  end

  def test_dependency_container_clear_cache
    # Test ability to clear cached services
    creation_count = 0
    @container.register(:clearable_service) do
      creation_count += 1
      "service_instance"
    end
    
    # Resolve service to cache it
    @container.resolve(:clearable_service)
    assert_equal 1, creation_count
    
    # Clear cache
    @container.clear_cache
    
    # Resolve again should recreate
    @container.resolve(:clearable_service)
    assert_equal 2, creation_count
  end

  def test_dependency_container_thread_safety
    # Test basic thread safety for service resolution
    creation_count = 0
    @container.register(:thread_safe_service) do
      creation_count += 1
      sleep(0.01)  # Small delay to increase chance of race condition
      "thread_safe_instance"
    end
    
    threads = []
    results = []
    
    # Create multiple threads resolving the same service
    5.times do
      threads << Thread.new do
        results << @container.resolve(:thread_safe_service)
      end
    end
    
    threads.each(&:join)
    
    # Should only create service once despite multiple threads
    assert_equal 1, creation_count
    # All results should be the same instance
    assert results.all? { |result| result == "thread_safe_instance" }
  end
end
