# frozen_string_literal: true

module SeigenWatchdog
  module Killers
    # Base class for all killers
    class Base
      # @rbs return: void
      def kill!
        raise NotImplementedError, "#{self.class} must implement #kill!"
      end
    end
  end
end
