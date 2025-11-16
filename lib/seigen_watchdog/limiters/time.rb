# frozen_string_literal: true

module SeigenWatchdog
  module Limiters
    # Limiter based on execution time
    class Time < Base
      # @rbs @max_duration: Numeric
      # @rbs @start_time: Float?

      attr_reader :start_time #: Float?
      attr_reader :max_duration #: Numeric

      # @rbs max_duration: Numeric
      # @rbs return: void
      def initialize(max_duration:)
        super()
        @max_duration = max_duration
        @start_time = nil
      end

      # Called when monitor starts - records the start time
      # @rbs return: void
      def started
        @start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      end

      # @rbs return: bool
      def exceeded?
        elapsed_time >= @max_duration
      end

      private

      # @rbs return: Float
      def elapsed_time
        return 0.0 if @start_time.nil?

        Process.clock_gettime(Process::CLOCK_MONOTONIC) - @start_time
      end
    end
  end
end
