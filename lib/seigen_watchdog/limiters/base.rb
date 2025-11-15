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
    end
  end
end
