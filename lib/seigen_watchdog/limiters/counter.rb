# frozen_string_literal: true

# rbs_inline: enabled

module SeigenWatchdog
  module Limiters
    # Limiter based on iteration count
    class Counter < Base
      attr_reader :max_count #: Integer

      # @param max_count [Integer] maximum count allowed
      # @param initial [Integer] initial counter value (default: 0)
      def initialize(max_count:, initial: 0)
        super()
        @max_count = max_count
        @count = initial
        @mutex = Mutex.new
      end

      # Increments the counter by the specified amount
      # @param count [Integer] the amount to increment (default: 1)
      # @return [void]
      def increment(count = 1)
        @mutex.synchronize { @count += count }
      end

      # Decrements the counter by the specified amount
      # @param count [Integer] the amount to decrement (default: 1)
      # @return [void]
      def decrement(count = 1)
        @mutex.synchronize { @count -= count }
      end

      # Resets the counter to the specified initial value
      # @param initial [Integer] value to reset counter to (default: 0)
      # @return [void]
      def reset(initial = 0)
        @mutex.synchronize { @count = initial }
      end

      # @return [Boolean] true if current count exceeds or equals the maximum
      def exceeded?
        @mutex.synchronize { @count >= @max_count }
      end
    end
  end
end
