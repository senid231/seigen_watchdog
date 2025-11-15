# frozen_string_literal: true

module SeigenWatchdog
  module Limiters
    # Limiter based on execution time
    class Time < Base
      # @param max_duration [Numeric] maximum duration in seconds
      def initialize(max_duration:)
        super()
        @max_duration = max_duration
        @start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      end

      # @return [Boolean] true if elapsed time exceeds the maximum duration
      def exceeded?
        elapsed_time >= @max_duration
      end

      private

      def elapsed_time
        Process.clock_gettime(Process::CLOCK_MONOTONIC) - @start_time
      end
    end
  end
end
