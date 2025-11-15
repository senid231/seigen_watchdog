# frozen_string_literal: true

require 'get_process_mem'

module SeigenWatchdog
  module Limiters
    # Limiter based on RSS memory usage
    class RSS < Base
      # @param max_rss [Integer] maximum RSS memory in bytes
      def initialize(max_rss:)
        super()
        @max_rss = max_rss
        @mem = GetProcessMem.new
      end

      # @return [Boolean] true if current RSS exceeds the maximum
      def exceeded?
        @mem.bytes >= @max_rss
      end
    end
  end
end
