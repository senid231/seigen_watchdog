# frozen_string_literal: true

# rbs_inline: enabled

module SeigenWatchdog
  module Limiters
    # Limiter based on a custom checker lambda
    class Custom < Base
      # @rbs @checker: Proc | #call
      # @rbs checker: Proc | #call
      # @rbs return: void
      def initialize(checker:)
        super()
        @checker = checker
      end

      # @rbs return: bool
      def exceeded?
        @checker.call
      end
    end
  end
end
