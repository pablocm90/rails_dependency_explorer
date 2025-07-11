# frozen_string_literal: true

module RailsDependencyExplorer
  module Analysis
    # Interface for analyzers that calculate dependency statistics.
    # Defines the contract for statistics calculation functionality.
    # Part of Phase 1.2 interface extraction (Tidy First - Structural).
    module StatisticsInterface
      # Calculates statistics from the dependency data.
      # @return [Hash] Hash containing various dependency statistics
      def calculate_statistics
        raise NotImplementedError, "#{self.class} must implement #calculate_statistics"
      end
    end
  end
end
