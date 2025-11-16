# frozen_string_literal: true

module SeigenWatchdog
  module Limiters
    # Base class for all limiters
    class Base
      # @rbs return: bool
      def exceeded?
        raise NotImplementedError, "#{self.class} must implement #exceeded?"
      end

      # Called when the limiter is started (when monitor initializes)
      # @rbs return: void
      def started; end

      # Called when the limiter is stopped (when monitor stops)
      # @rbs return: void
      def stopped; end
    end
  end
end
