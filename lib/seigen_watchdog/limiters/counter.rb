# frozen_string_literal: true

module SeigenWatchdog
  module Limiters
    # Limiter based on iteration count
    class Counter < Base
      # @rbs @max_count: Integer
      # @rbs @count: Integer
      # @rbs @mutex: Thread::Mutex

      attr_reader :max_count #: Integer

      # @rbs max_count: Integer
      # @rbs initial: Integer
      # @rbs return: void
      def initialize(max_count:, initial: 0)
        super()
        @max_count = max_count
        @count = initial
        @mutex = Mutex.new
      end

      # Increments the counter by the specified amount
      # @rbs count: Integer
      # @rbs return: void
      def increment(count = 1)
        @mutex.synchronize { @count += count }
      end

      # Decrements the counter by the specified amount
      # @rbs count: Integer
      # @rbs return: void
      def decrement(count = 1)
        @mutex.synchronize { @count -= count }
      end

      # Resets the counter to the specified initial value
      # @rbs initial: Integer
      # @rbs return: void
      def reset(initial = 0)
        @mutex.synchronize { @count = initial }
      end

      # @rbs return: bool
      def exceeded?
        @mutex.synchronize { @count >= @max_count }
      end
    end
  end
end
