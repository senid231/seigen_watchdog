# frozen_string_literal: true

module SeigenWatchdog
  module Killers
    # Base class for all killers
    class Base
      # Kills the application
      def kill!
        raise NotImplementedError, "#{self.class} must implement #kill!"
      end
    end
  end
end
