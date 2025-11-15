# frozen_string_literal: true

module SeigenWatchdog
  module Killers
    # Killer that sends a signal to the current process
    class Signal < Base
      # @param signal [String, Symbol] the signal to send (e.g., 'INT', 'TERM', 'KILL')
      def initialize(signal:)
        super()
        @signal = signal.to_s
      end

      # Sends the signal to the current process
      def kill!
        Process.kill(@signal, Process.pid)
      end
    end
  end
end
