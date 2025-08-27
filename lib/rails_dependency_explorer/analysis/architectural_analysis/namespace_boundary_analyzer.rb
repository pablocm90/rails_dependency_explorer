# frozen_string_literal: true

module RailsDependencyExplorer
  module Analysis
    module ArchitecturalAnalysis
    # Analyzes namespace boundary violations in dependency data
    # Identifies dependencies that cross namespace boundaries inappropriately
    # Part of Test A2: Namespace boundary analysis
    class NamespaceBoundaryAnalyzer
      # Severity levels for violations
      SEVERITY_HIGH = "high"
      SEVERITY_MEDIUM = "medium"
      SEVERITY_LOW = "low"

      # Penalty values for health score calculation
      PENALTY_HIGH = 3.0
      PENALTY_MEDIUM = 2.0
      PENALTY_LOW = 1.0

      # Health score bounds
      PERFECT_HEALTH_SCORE = 10.0
      WORST_HEALTH_SCORE = 0.0

      def initialize(dependency_data)
        @dependency_data = dependency_data || {}
        @violations = nil
      end

      # Analyze dependency data for namespace boundary violations
      # @return [Array<Hash>] Array of violation details
      def analyze
        return [] if @dependency_data.empty?

        @violations = []

        @dependency_data.each do |source_class, dependencies|
          next unless valid_class_name?(source_class)
          next unless dependencies.is_a?(Array)

          source_namespace = extract_namespace(source_class)

          dependencies.each do |dependency_hash|
            next unless dependency_hash.is_a?(Hash)

            dependency_hash.each_key do |target_class|
              next unless valid_class_name?(target_class)

              target_namespace = extract_namespace(target_class)

              # Skip same-namespace dependencies (not violations)
              next if source_namespace == target_namespace

              violation = create_violation(source_class, target_class, source_namespace, target_namespace)
              @violations << violation
            end
          end
        end

        @violations
      end

      # Get violations grouped by namespace pair
      # @return [Hash] Violations grouped by "Source -> Target" namespace pairs
      def violations_by_namespace_pair
        analyze if @violations.nil?
        
        grouped = {}
        @violations.each do |violation|
          key = "#{violation[:source_namespace]} -> #{violation[:target_namespace]}"
          grouped[key] ||= []
          grouped[key] << violation
        end
        
        grouped
      end

      # Calculate boundary health score (0.0 = worst, 10.0 = perfect)
      # @return [Float] Health score based on violation severity and count
      def boundary_health_score
        violations = analyze

        return PERFECT_HEALTH_SCORE if violations.empty?

        # Calculate penalty based on violation severity
        total_penalty = violations.sum do |violation|
          case violation[:severity]
          when SEVERITY_HIGH then PENALTY_HIGH
          when SEVERITY_MEDIUM then PENALTY_MEDIUM
          when SEVERITY_LOW then PENALTY_LOW
          else PENALTY_LOW
          end
        end

        # Scale penalty and subtract from perfect score
        penalty_factor = [total_penalty / 10.0, PERFECT_HEALTH_SCORE].min
        [PERFECT_HEALTH_SCORE - penalty_factor, WORST_HEALTH_SCORE].max
      end

      # Get all boundary violations (alias for analyze)
      # @return [Array<Hash>] Array of violation details
      def boundary_violations
        analyze
      end

      # Calculate violation severity based on namespace characteristics
      # @param source_namespace [String] Source namespace
      # @param target_namespace [String] Target namespace
      # @return [String] Severity level: "high", "medium", or "low"
      def violation_severity(source_namespace, target_namespace)
        # External dependencies are high severity (either direction)
        return SEVERITY_HIGH if target_namespace.start_with?("External::")
        return SEVERITY_HIGH if source_namespace.start_with?("External::")

        # Internal cross-namespace dependencies are medium severity
        return SEVERITY_MEDIUM if source_namespace != target_namespace

        # Same namespace (shouldn't happen in violations) is low
        SEVERITY_LOW
      end

      private

      # Validate that a class name is a non-empty string
      # @param class_name [Object] Class name to validate
      # @return [Boolean] True if valid
      def valid_class_name?(class_name)
        class_name.is_a?(String) && !class_name.empty?
      end

      # Extract namespace from class name
      # @param class_name [String] Full class name
      # @return [String] Namespace portion
      def extract_namespace(class_name)
        parts = class_name.split("::")
        return class_name if parts.size <= 1

        # Return all parts except the last (class name)
        parts[0..-2].join("::")
      end

      # Create violation hash with all required details
      # @param source_class [String] Source class name
      # @param target_class [String] Target class name
      # @param source_namespace [String] Source namespace
      # @param target_namespace [String] Target namespace
      # @return [Hash] Violation details
      def create_violation(source_class, target_class, source_namespace, target_namespace)
        severity = violation_severity(source_namespace, target_namespace)
        
        {
          source_class: extract_class_name(source_class),
          target_class: extract_class_name(target_class),
          source_namespace: source_namespace,
          target_namespace: target_namespace,
          severity: severity,
          recommendation: generate_recommendation(source_namespace, target_namespace, severity)
        }
      end

      # Extract just the class name from full class path
      # @param full_class_name [String] Full class name with namespace
      # @return [String] Just the class name
      def extract_class_name(full_class_name)
        full_class_name.split("::").last
      end

      # Generate recommendation for fixing the violation
      # @param source_namespace [String] Source namespace
      # @param target_namespace [String] Target namespace
      # @param severity [String] Violation severity
      # @return [String] Recommendation text
      def generate_recommendation(source_namespace, target_namespace, severity)
        case severity
        when SEVERITY_HIGH
          generate_high_severity_recommendation(target_namespace)
        when SEVERITY_MEDIUM
          "Consider introducing an interface or service layer to reduce direct cross-namespace coupling"
        else
          "Review dependency necessity and consider refactoring for better encapsulation"
        end
      end

      # Generate specific recommendations for high-severity violations
      # @param target_namespace [String] Target namespace
      # @return [String] Recommendation text
      def generate_high_severity_recommendation(target_namespace)
        if target_namespace.start_with?("External::")
          "Consider introducing an adapter or facade to isolate external dependency"
        else
          "High-severity cross-namespace dependency detected - consider architectural refactoring"
        end
      end
    end
  end
end
end
