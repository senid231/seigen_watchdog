# frozen_string_literal: true

module SeigenWatchdog
  module Limiters
    # Base class for all limiters
    class Base
      # Checks if the limit has been exceeded
      # @return [Boolean] true if the limit has been exceeded
      def exceeded?
        raise NotImplementedError, "#{self.class} must implement #exceeded?"
      end

      # Called when the limiter is started (when monitor initializes)
      # Override in subclasses to perform initialization (e.g., register resources)
      def started; end

      # Called when the limiter is stopped (when monitor stops)
      # Override in subclasses to perform cleanup (e.g., unregister resources)
      def stopped; end
    end
  end
end
