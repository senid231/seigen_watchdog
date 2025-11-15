# frozen_string_literal: true

module SeigenWatchdog
  module Limiters
    # Limiter based on a custom checker lambda
    class Custom < Base
      # @param checker [Proc,#call] a lambda/proc or object respond to #call that returns true when the limit is exceeded
      def initialize(checker:)
        super()
        @checker = checker
      end

      # @return [Boolean] the result of calling the checker
      def exceeded?
        @checker.call
      end
    end
  end
end
