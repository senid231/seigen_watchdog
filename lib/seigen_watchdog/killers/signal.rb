# frozen_string_literal: true

module SeigenWatchdog
  module Killers
    # Killer that sends a signal to the current process
    class Signal < Base
      # @rbs @signal: String

      attr_reader :signal #: String

      # @rbs signal: String | Symbol
      # @rbs return: void
      def initialize(signal:)
        super()
        @signal = signal.to_s
      end

      # Sends the signal to the current process
      # @rbs return: void
      def kill!
        Process.kill(@signal, Process.pid)
      end
    end
  end
end
